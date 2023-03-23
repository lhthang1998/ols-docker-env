#!/usr/bin/env bash
CK_RESULT=''
LSDIR='/usr/local/lsws'
LS_HTTPD_CONF="${LSDIR}/conf/httpd_config.xml"
OLS_HTTPD_CONF="${LSDIR}/conf/httpd_config.conf"
EPACE='        '

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow '-A, --add [DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Will add domain to listener and creat a virtual host from template"
    echow '-sub , --sub [PRIMARY_DOMAIN] [SUB_DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Will add sub domain to a virtual host"
    echow '-delsub , --delsub [PRIMARY_DOMAIN] [SUB_DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Will delete sub domain to a virtual host"
    echow '-updp , --updp [PRIMARY_DOMAIN] [NEW_PRIMARY_DOMAIN] [ARRAY_ALIAS_DOMAIN]'
    echo "${EPACE}${EPACE}Will update primary domain to a virtual host"
    echow '-D, --del [DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Will delete domain from listener"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help."
}

check_lsv(){
    if [ -f ${LSDIR}/bin/openlitespeed ]; then
        LSV='openlitespeed'
    elif [ -f ${LSDIR}/bin/litespeed ]; then
        LSV='lsws'
    else
        echo 'Version not exist, abort!'
        exit 1
    fi
}

dot_escape(){
    ESCAPE=$(echo ${1} | sed 's/\./\\./g')
}

check_duplicate(){
    CK_RESULT=$(grep -E "${1}" ${2})
}

fst_match_line(){
    FIRST_LINE_NUM=$(grep -n -m 1 ${1} ${2} | awk -F ':' '{print $1}')
}
fst_match_after(){
    FIRST_NUM_AFTER=$(tail -n +${1} ${2} | grep -n -m 1 ${3} | awk -F ':' '{print $1}')
}
lst_match_line(){
    fst_match_after ${1} ${2} ${3}
    LAST_LINE_NUM=$((${FIRST_LINE_NUM}+${FIRST_NUM_AFTER}-1))
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

check_www(){
    CHECK_WWW=$(echo ${1} | cut -c1-4)
    if [[ ${CHECK_WWW} == www. ]] ; then
        echo 'www domain shoudnt be passed!'
        exit 1
    fi
}

www_domain(){
    check_www ${1}
    WWW_DOMAIN=$(echo www.${1})
}

add_ls_domain(){
    fst_match_line 'docker.xml</templateFile>' ${LS_HTTPD_CONF}
    NEWNUM=$((FIRST_LINE_NUM+2))
    sed -i "${NEWNUM}i \ \ \ \ \ \ <member>\n \ \ \ \ \ \ \ <vhName>${DOMAIN}</vhName>\n \ \ \ \ \ \ \ <vhDomain>${DOMAIN},${WWW_DOMAIN}</vhDomain>\n \ \ \ \ \ \ </member>" ${LS_HTTPD_CONF}
}

add_ols_domain(){
    perl -0777 -p -i -e 's/(vhTemplate docker \{[^}]+)\}*(^.*listeners.*$)/\1$2
  member '${DOMAIN}' {
    vhDomain              '${DOMAIN},${WWW_DOMAIN}'
  }/gmi' ${OLS_HTTPD_CONF}
}

add_domain(){
    check_lsv
    dot_escape ${1}
    DOMAIN=${ESCAPE}
    www_domain ${1}
    if [ "${LSV}" = 'lsws' ]; then
        check_duplicate "vhDomain.*${DOMAIN}" ${LS_HTTPD_CONF}
        if [ "${CK_RESULT}" != '' ]; then
            echo "# It appears the domain already exist! Check the ${LS_HTTPD_CONF} if you believe this is a mistake!"
            exit 1
        fi
        add_ls_domain
    elif [ "${LSV}" = 'openlitespeed' ]; then
        check_duplicate "member.*${DOMAIN}" ${OLS_HTTPD_CONF}
        if [ "${CK_RESULT}" != '' ]; then
            echo "# It appears the domain already exist! Check the ${OLS_HTTPD_CONF} if you believe this is a mistake!"
            exit 1
        fi  
        add_ols_domain      
    fi
}

del_ls_domain(){
    fst_match_line "<vhName>*${1}" ${LS_HTTPD_CONF}
    FIRST_LINE_NUM=$((FIRST_LINE_NUM-1))
    lst_match_line ${FIRST_LINE_NUM} ${LS_HTTPD_CONF} '</member>'
    sed -i "${FIRST_LINE_NUM},${LAST_LINE_NUM}d" ${LS_HTTPD_CONF}
}

del_ols_domain(){
    fst_match_line ${1} ${OLS_HTTPD_CONF}
    lst_match_line ${FIRST_LINE_NUM} ${OLS_HTTPD_CONF} '}'
    sed -i "${FIRST_LINE_NUM},${LAST_LINE_NUM}d" ${OLS_HTTPD_CONF}
}

del_domain(){
    check_lsv
    dot_escape ${1}
    DOMAIN=${ESCAPE}
    if [ "${LSV}" = 'lsws' ]; then
        check_duplicate "vhDomain.*${DOMAIN}" ${LS_HTTPD_CONF}
        if [ "${CK_RESULT}" = '' ]; then
            echo "# Domain non-exist! Check the ${LS_HTTPD_CONF} if you believe this is a mistake!"
            exit 1
        fi
        del_ls_domain ${1}
    elif [ "${LSV}" = 'openlitespeed' ]; then
        check_duplicate "member.*${DOMAIN}" ${OLS_HTTPD_CONF}
        if [ "${CK_RESULT}" = '' ]; then
            echo "# Domain non-exist! Check the ${OLS_HTTPD_CONF} if you believe this is a mistake!"
            exit 1
        fi
        del_ols_domain ${1}
    fi
}

add_alias_domain(){
    MATCH_LINE=$(awk "/vhDomain.*${1}/,/}/"  ${OLS_HTTPD_CONF})
    if [[ "${MATCH_LINE}" == *"vhAliases"* ]]; then
      MATCH_LINE=$(echo "${MATCH_LINE}" | grep -E "vhAliases")
      sed -i "/^${MATCH_LINE}/s/$/, ${2}/" ${OLS_HTTPD_CONF}
    else
      MATCH_LINE=$(grep -E "vhDomain" ${OLS_HTTPD_CONF} | grep ${1})
      sed -i "/${MATCH_LINE}/a \ \ \ \ vhAliases             ${2}" ${OLS_HTTPD_CONF}
    fi
    exit 0
}

del_alias_domain(){
    MATCH_LINE=$(awk "/vhDomain.*${1}/,/}/"  ${OLS_HTTPD_CONF})
    if [[ "${MATCH_LINE}" == *"vhAliases"* ]]; then
      MATCH_LINE=$(echo "${MATCH_LINE}" | grep -E "vhAliases")
      count=$(echo $MATCH_LINE | grep -c ,)
      if [ "${count}" = 0 ]; then
        echo "Delete last sub domain"
        echo $MATCH_LINE | sed -i "/${2}/d" ${OLS_HTTPD_CONF}
      else
        echo $MATCH_LINE | sed -i s/", ${2}"// ${OLS_HTTPD_CONF}
      fi
    else
      echo 'No sub domain to delete'
    fi
    exit 0
}

update_primary_domain(){
    MATCH_LINE=$(grep -E "vhDomain" ${OLS_HTTPD_CONF} | grep ${1})
    sed -i "s/${MATCH_LINE}/    vhDomain              ${2}/g" ${OLS_HTTPD_CONF}
    if grep -A 1 "vhDomain.*${1}" ${OLS_HTTPD_CONF} | tail -n 1 | grep -q "vhAliases";
    then
        add_alias_domain ${2} ${3}
    else
        MATCH_LINE=$(grep -E "vhAliases" ${OLS_HTTPD_CONF} | grep ${2})
        sed -i "s/${MATCH_LINE}/    vhAliases              ${3}/g" ${OLS_HTTPD_CONF}
    fi
    exit 0
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[aA] | -add | --add) shift
            add_domain ${1}
            ;;
        -[dD] | -del | --del | --delete) shift
            del_domain ${1}
            ;;
        -[aS] | -sub | --sub) shift
            add_alias_domain ${1} ${2}
            ;;
        -[dS] | -delsub | --delsub) shift
            del_alias_domain ${1} ${2}
            ;;
        -[uD] | -updp | --updp) shift
            update_primary_domain ${1} ${2} ${3}
            ;;
        *) 
            help_message
            ;;
    esac
    shift
done
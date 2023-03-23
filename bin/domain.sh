#!/usr/bin/env bash
CONT_NAME='litespeed'
EPACE='        '
DOMAIN=''
SUBDOMAIN=''

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow "-A, --add [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -A example.com, will add the domain to Listener and auto create a new virtual host."
    echow "-D, --del [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -D example.com, will delete the domain from Listener."
    echow '-sub, --sub [primary_domain] [sub_domain]'
    echo "${EPACE}${EPACE}Example: domain.sh --sub example.com subdomain.com, will add an alias domain to Listener."
    echow '-delsub, --delsub [primary_domain] [sub_domain]'
    echo "${EPACE}${EPACE}Example: domain.sh --delsub example.com subdomain.com, will remove an alias domain to Listener."
    echow '-updp, --updp [primary_domain] [new_primary_domain] [array_alias_domain]'
    echo "${EPACE}${EPACE}Example: domain.sh --updp example.com newdomain.com, will update a primary domain to Listener."
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."    
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

add_domain(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --add ${1}"
    if [ ! -d "./sites/${1}" ]; then 
        mkdir -p ./sites/${1}/{html,logs,certs}
    fi
    bash bin/webadmin.sh -r
}

del_domain(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --del ${1}"
    bash bin/webadmin.sh -r
}

add_alias_domain(){
    echo "Primary domain: ${1}, sub domain: ${2}"
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --sub ${1} ${2}"
    bash bin/webadmin.sh -r
}

del_alias_domain(){
    echo "Primary domain: ${1}, sub domain: ${2}"
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --delsub ${1} ${2}"
    bash bin/webadmin.sh -r
}

update_primary_domain(){
    echo "Primary domain: ${1}, new primary domain: ${2}"
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --updp ${1} ${2} ${3}"
    bash bin/webadmin.sh -r
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
        -[uS] | -sub | --sub) shift
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
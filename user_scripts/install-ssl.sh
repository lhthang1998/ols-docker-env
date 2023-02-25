#!/bin/bash
DOMAIN=""
ENAIL="lhthang.98@gmail.com"

folder_name='/root/ols-docker-env'

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow "-A, --add [add ssl]"
    echow "-K, --revoke [revoke ssl]"
    echow "-R, --remove [remove ssl]"
    echow "-E, --email [EMAIL]"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
    exit 0
}

check_input(){
    if [ -z "${1}" ]; then
        help_message 2
    fi
}

add_ssl(){
  echo "Install ssl"
  cd ${folder_name}
  ./bin/acme.sh --install --email ${EMAIL}
  ca_ssl='DEFAULT_CA=$CA_ZEROSSL'
  new_ls_ssl='DEFAULT_CA=$CA_LETSENCRYPT_V2'
  sed -i "s/${ca_ssl}/${new_ls_ssl}/g" acme/acme.sh
  ./bin/acme.sh --domain ${DOMAIN}
  exit 0
}

revoke_ssl(){
  echo "Redeploy ssl"
  cd ${folder_name}
  ./bin/acme.sh --revoke --domain ${DOMAIN} --force
  ./bin/acme.sh --domain ${DOMAIN} --force
  exit 0
}

remove_ssl(){
  echo "Remove ssl"
  cd ${folder_name}
  path=`echo "./acme/certs/${DOMAIN}"`
  rm -rf $path
  ./bin/acme.sh --remove --domain ${DOMAIN} --force
  exit 0
}


check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[aA] | -add | --add) shift
            check_input "${1}" "${2}"
            DOMAIN="${1}"
            EMAIL="${2}"
            add_ssl
            ;;
        -[kK] | -revoke | --revoke) shift
            check_input "${1}"
            DOMAIN="${1}"
            revoke_ssl
            ;;
         -[rR] | -remove | --remove) shift
            check_input "${1}"
            remove_ssl
            ;;
        *)
            help_message
            ;;
    esac
    shift
done
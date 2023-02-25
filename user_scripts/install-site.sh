#!/bin/bash
tabb_url="https://app.tabb.vn"
fcm_url="https://fcm.googleapis.com/v1/projects/tabbdemo/messages:send"
APP_NAME='wordpress'
DEFAULT_SSL='true'
DOMAIN=''
TITLE='Demo'
EMAIL='lhthang.98@gmail.com'
ADMIN_USERNAME='admin'
ADMIN_PASSWORD='admin321'
DATABASE_NAME=''
DATABASE_USER=''
DATABASE_PASSWORD=''

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow "-A, --app [wordpress, empty]"
    echow "-D, --domain [DOMAIN]"
    echow "-T, --title [SITE_TITLE]"
    echow "-E, --email [ADMIN_EMAIL]"
    echow "-U, --username [ADMIN_USERNAME]"
    echow "-P, --password [ADMIN_PASSWORD]"
    echow "-db, --database [DATABASE_NAME]"
    echow "-bU, --database-username [DATABASE_USER]"
    echow "-bP, --database-password [DATABASE_PASSWORD]"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
    exit 0
}

check_input(){
    if [ -z "${1}" ]; then
        help_message 2
    fi
}

main(){
  if [ "${APP_NAME}" != "wordpress" ] && [ "${APP_NAME}" != "empty" ]; then
    echo '--app must be in [wordpress, empty]'
    exit 1
  fi

  folder_name="/root/ols-docker-env"
  cd ${folder_name}

  ./bin/acme.sh --install --email ${EMAIL}
  ./bin/domain.sh -add ${DOMAIN}
  #
  if [[ "${DEFAULT_SSL}" == "true" ]];
  then
    echo "Install ssl"
    ca_ssl='DEFAULT_CA=$CA_ZEROSSL'
    new_ls_ssl='DEFAULT_CA=$CA_LETSENCRYPT_V2'
    sed -i "s/${ca_ssl}/${new_ls_ssl}/g" acme/acme.sh
    ./bin/acme.sh --domain ${DOMAIN}
  fi

  if [ "${APP_NAME}" = "empty" ]; then
    echo 'Installing empty site...'
    ./bin/appinstall.sh --app empty --domain ${DOMAIN} --title ${TITLE}
  fi
  #
  if [ "${APP_NAME}" = "wordpress" ]; then
    echo 'Installing Wordpress site...'
    ./bin/database.sh --domain ${DOMAIN} --user ${DATABASE_USER} --password ${DATABASE_PASSWORD} --database ${DATABASE_NAME}

    ./bin/appinstall.sh --app wordpress --domain ${DOMAIN} --title ${TITLE} --username ${ADMIN_USERNAME} --password ${ADMIN_PASSWORD} --email ${EMAIL}

  fi

  curl $domain
  if [ "$?" -ne 0 ]
  then
    echo "OK. Created site successfully"
  else
    echo "NOK. Can not access site. Please check it"
  fi
  echo 'Completely'
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[aA] | -app | --app) shift
            check_input "${1}"
            APP_NAME="${1}"
            ;;
        -[sS] | -ssl | --ssl) shift
            check_input "${1}"
            DEFAULT_SSL="${1}"
            ;;
        -[dD] | -domain | --domain) shift
            check_input "${1}"
            DOMAIN="${1}"
            ;;
        -[tT] | -title | --title) shift
            check_input "${1}"
            TITLE="${1}"
            ;;
        -[eE] | -email | --email) shift
            check_input "${1}"
            EMAIL="${1}"
            ;;
         -[uU] | -username | --username) shift
            check_input "${1}"
            ADMIN_USERNAME="${1}"
            ;;
        -[pP] | -password | --password) shift
            check_input "${1}"
            ADMIN_PASSWORD="${1}"
            ;;
        -[dB] | -database | --database) shift
            check_input "${1}"
            DATABASE_NAME="${1}"
            ;;
        -[bU] | -dbuser | --dbuser) shift
            check_input "${1}"
            DATABASE_USER="${1}"
            ;;
        -[bP] | -dbpassword | --dbpassword) shift
            check_input "${1}"
            DATABASE_PASSWORD="${1}"
            ;;
        *)
            help_message
            ;;
    esac
    shift
done

main
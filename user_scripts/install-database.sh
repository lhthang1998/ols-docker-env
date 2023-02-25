#!/bin/bash
tabb_url="https://app.tabb.vn"
fcm_url="https://fcm.googleapis.com/v1/projects/tabbdemo/messages:send"
ANY="'%'"
ACTION=''
DATABASE_NAME=''
DATABASE_USERNAME=''
DATABASE_PASSWORD=''
DATABASE_COLLATION='utf8mb4_general_ci'

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow "-A, --action [ADD, DELETE, UPDATE_PASSWORD]"
    echow "-D, --database [DATABASE_NAME]"
    echow "-U, --username [DATABASE_USERNAME]"
    echow "-P, --password [DATABASE_PASSWORD]"
    echow "-C, --collation [DATABASE_COLLATION]"
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
  if [ "${ACTION}" != 'ADD' ] && [ "${ACTION}" != 'DELETE' ] && [ "${ACTION}" != 'UPDATE_PASSWORD' ]; then
    echo "Action could only be: ADD, DELETE, UPDATE_PASSWORD"
    exit 1
  fi

  if [ "$ACTION" = "ADD" ]
  then
    database_charset=(${DATABASE_COLLATION//_/ })
    docker exec -it mysql su -c "test -e /var/lib/mysql/${DATABASE_NAME}"
    if [ ${?} = 0 ]; then
        echo "Database ${1} already exist, skip DB creation!"
        exit 0
    fi
    docker exec -it mysql su -c 'mysql -uroot -p${MYSQL_ROOT_PASSWORD} \
    -e "CREATE DATABASE '${DATABASE_NAME}' CHARACTER SET '\'${database_charset[0]}\'' COLLATE '${DATABASE_COLLATION}';" \
    -e "GRANT ALL PRIVILEGES ON '${DATABASE_NAME}'.* TO '${DATABASE_USERNAME}'@'${ANY}' IDENTIFIED BY '\'${DATABASE_PASSWORD}\'';" \
    -e "FLUSH PRIVILEGES;"'
  fi

  if [ "$ACTION" = "DELETE" ]
  then
      docker exec -it mysql su -c 'mysql -uroot -p${MYSQL_ROOT_PASSWORD} \
      -e "DROP USER '${DATABASE_USERNAME}'@'${ANY}';" \
      -e "DROP DATABASE '${DATABASE_NAME}' ;"'
  fi

  if [ "$ACTION" = "UPDATE_PASSWORD" ]
  then
      docker exec -it mysql su -c 'mysql -uroot -p${MYSQL_ROOT_PASSWORD} \
      -e "ALTER USER '${DATABASE_USERNAME}'@'${ANY}' IDENTIFIED BY '\'${DATABASE_PASSWORD}\'';"'
  fi
  echo "Done"
}


check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[aA] | -action | --action) shift
            check_input "${1}"
            ACTION="${1}"
            ;;
        -[dD] | -database | --database) shift
            check_input "${1}"
            DATABASE_NAME="${1}"
            ;;
         -[uU] | -username | --username) shift
            check_input "${1}"
            DATABASE_USERNAME="${1}"
            ;;
        -[pP] | -password | --password) shift
            check_input "${1}"
            DATABASE_PASSWORD="${1}"
            ;;
        -[cC] | -collation | --collation) shift
            check_input "${1}"
            DATABASE_COLLATION="${1}"
            ;;
        *)
            help_message
            ;;
    esac
    shift
done

main

#!/usr/bin/env bash
EMAIL=''
NO_EMAIL=''
INSTAL=''
DOMAIN=''

help_message(){
    echo 'Command [-domain XX]'
    echo 'Command --install [--email XX]'
    echo 'Command --install --no-email'
    echo 'Example: acme.sh -domain '
    echo 'Example: acme.sh --install --email example@example.com'
    echo 'Example: acme.sh --install --no-email'
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

ck_acme(){
    if ! docker-compose exec litespeed su -c "test -f /root/.acme.sh/acme.sh"; then
        echo "It seems like you didn't install /root/.acme.sh/acme.sh, please run bin/acme.sh --install"
        help_message
        exit 1
    fi
}

install_acme(){
        if [ ! -z ${NO_EMAIL} ]; then
            docker-compose exec litespeed su -c "cd;\
            wget https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh; chmod 755 acme.sh; \
            ./acme.sh --install  \
            --cert-home  ~/.acme.sh/certs; \
            rm ~/acme.sh"
        else
            if [ -z ${EMAIL} ]; then
                echo "Error: You didn't specify the email you want to receive lets encrypt notifications on. Please add --email EMAIL"
                exit
                else
                    docker-compose exec litespeed su -c "cd;\
                    wget https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh; chmod 755 acme.sh; \
                    ./acme.sh --install  \
                    --cert-home  ~/.acme.sh/certs \
                    --accountemail  ${EMAIL}; \
                    rm ~/acme.sh"
                fi
        fi

}

install_cert(){
    docker-compose exec litespeed su -c "/root/.acme.sh/acme.sh --issue -d ${DOMAIN} -w /var/www/vhosts/${DOMAIN}/html/"
    bin/webadmin.sh -r

}

main(){
    if [ -z "${INSTALL}" ]; then
    ck_acme
    else
    install_acme ${EMAIL} ${NO_EMAIL}
    echo 'Acme installed, you can now issue your cert with bin/acme.sh -domain '
    exit 1
    fi
    install_cert ${DOMAIN}
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            exit 1
            ;;
        -domain | -d ) shift
            check_input "${1}"
            DOMAIN="${1}"
            ;;
        --install ) 
            INSTALL=true
            ;;
        --email ) shift
            check_input "${1}"
            EMAIL="${1}"
            ;;
        --no-email ) shift
            NO_EMAIL=true
            ;;            
        *) 
            help_message
            exit 1
            ;;              
    esac
    shift
done

main
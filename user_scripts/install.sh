#!/bin/bash
root_passwd=`openssl rand -base64 10`
user_passwd=`openssl rand -base64 10`
webadmin_passwd=`openssl rand -base64 10`

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

set -euo pipefail

sudo service docker start
sudo apt install docker-compose -y
sleep 1
folder_name="/root/ols-docker-env"
if [ -d "${folder_name}" ]
then
    echo "Directory ${folder_name} is exist"
    cd ${folder_name}
    docker-compose down
    rm -rf ${folder_name}
fi

git clone https://github.com/lhthang1998/ols-docker-env.git ${folder_name}
chmod +x -R ${folder_name}
rm -rf ${folder_name}/.env

cat << EOF >> ${folder_name}/.env
TimeZone=Asia/Ho_Chi_Minh
OLS_VERSION=1.7.16
PHP_VERSION=lsphp81
MYSQL_DATABASE=olsdockerenv
MYSQL_ROOT_PASSWORD=${root_passwd}
MYSQL_USER=lhthang
MYSQL_PASSWORD=${user_passwd}
WEBADMIN_PASSWD=${webadmin_passwd}
DOMAIN=localhost
EOF

cd ${folder_name}
docker-compose up -d
./bin/webadmin.sh ${webadmin_passwd}
./bin/webadmin.sh --mod-secure enable

echo "Done"
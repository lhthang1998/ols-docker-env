#!/bin/bash
dir_name="$1"
username="$2"
passwd="$3"

parentdir="$(dirname "$dir_name")"

if [[ ! -z $(grep "Match User $username" "/etc/ssh/sshd_config") ]];
then
echo "Already set up"
else
echo "Add new group: sftp_user"
sudo groupadd sftp_user
echo "Add user to sftp server"
echo -e "\n\n\n\n\n\y\n" |  sudo adduser --home $dir_name $username
echo -e "$passwd\n$passwd\n" | sudo passwd $username
#sudo chmod 755 $dir_name
sudo chgrp -R sftp_user $dir_name
sudo chmod -R 770 $dir_name
#cat << EOF >> /etc/ssh/sshd_config
#Match User $username
#  ChrootDirectory $dir_name
#EOF
fi
sudo systemctl restart ssh
echo "Done"
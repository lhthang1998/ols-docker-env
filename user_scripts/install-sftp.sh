#!/bin/bash
connection_time="$1"
dir_name="$2"
username="$3"
passwd="$4"

parentdir="$(dirname "$dir_name")"

if [[ ! -z $(grep "Match User $username" "/etc/ssh/sshd_config") ]];
then
echo "Already set up"
else
echo "Add user to sftp server"
sudo useradd -m $username -g sftp_user
echo -e "$passwd\n$passwd\n" | sudo passwd $username
sudo addgroup sftp_user
sudo chmod 755 $parentdir
sudo chown $username:root $dir_name
sudo chmod 775 $dir_name
cat << EOF >> /etc/ssh/sshd_config
#begin $username
Match User $username
ChrootDirectory $parentdir
PermitTunnel no
AllowAgentForwarding no
AllowTcpForwarding no
ForceCommand internal-sftp -d $dir_name
ClientAliveInterval $connection_time
ClientAliveCountMax 1
#end $username
EOF
fi
sudo systemctl restart ssh
echo "Done"
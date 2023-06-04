#!/bin/bash
dir_name="$1"
username="$2"
passwd="$3"
group="$4"
parentdir="$(dirname "$dir_name")"
basedir="$(basename "$dir_name")"

if id "$username" &>/dev/null; then
echo "Already set up"
else
echo "Add user to sftp server"
sudo groupadd $group
echo -e "$passwd\n$passwd\n\n\n\n\n\n\Y\n" |  sudo adduser --home $dir_name $username --ingroup $group
sudo setfacl -R -m u:$username:--- /var/tabb
sudo setfacl -R -m u:$username:--- /usr/local/tabb
for d in "$parentdir"/*/; do
    sudo setfacl -R -m u:$username:--- $d
done
sudo setfacl -R -m u:$username:rwx $dir_name
fi
sudo systemctl restart ssh
echo "Done"
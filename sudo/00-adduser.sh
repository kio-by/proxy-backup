#!/bin/bash

if [ ! -d /root/backup/scripts ]; then
    sudo mkdir -p /root/backup/scripts
    sudo ln -s "$(realpath ../root/telegram-ssh.sh)" /root/backup/scripts
    sudo ln -s "$(realpath ../root/telegram-message.sh)" /root/backup/scripts
    sudo ln -s "$(realpath ../root/google-api.sh)" /root/backup/scripts
    sudo ln -s "$(realpath ../root/run-backup.sh)" /root/backup/scripts
    sudo cp ../root/.env.default /root/backup/scripts/.env
    echo 'Scripts have been added in /root/backup/scripts'

else
    echo 'OK'
    echo 'Scripts have been found in /root/backup/scripts'
fi

# Enter Username or Usernames:
read -p 'Enter Username: ' USER
usernames=("b-$USER")
for username in "${usernames[@]}"; do
    home_dir="/home/$username"
    sudo useradd -m -d "$home_dir" -s /bin/bash "$username"
    sudo -u "$username" ssh-keygen -t rsa -b 2048 -f "$home_dir/.ssh/id_rsa" -N ""
    sudo -u "$username" cp "$home_dir"/.ssh/id_rsa.pub "$home_dir"/.ssh/authorized_keys
    sudo -u "$username" mkdir "$home_dir"/backup
    sudo -u "$username" mkdir "$home_dir"/backup/.temp-flag
    sudo -u "$username" touch "$home_dir"/backup/readme.md

    # create user script folder in root directory
    sudo mkdir -p /root/backup/$username
    echo "USER_NAME=$username" | sudo tee -a /root/backup/$username/.env.local
    sudo ln -s /root/backup/scripts/.env /root/backup/$username/.env
    sudo ln -s /root/backup/scripts/*.sh /root/backup/$username

    # add root cron note
    sudo crontab -u root -l >temp_cron
    echo "" >>temp_cron
    echo "# Task for $username" >>temp_cron
    echo "# * * * * * cd /root/backup/$username && /bin/bash /root/backup/$username/run-backup.sh >> /var/log/proxy-backup/$username.log 2>&1" >>temp_cron
    sudo crontab -u root temp_cron

    # Send ssh-keys to telegram
    source <(sudo cat /root/backup/scripts/telegram-ssh.sh)

    echo "=================================================================="
    echo "="
    echo "=  User '$username' added with home directory '$home_dir'"
    echo "="
    echo "=================================================================="
done

# Enter Username or Usernames:
read -p 'Enter Username or Usernames: ' USER
sudo deluser --remove-home $USER
sudo rm -rf /root/backup/$USER

echo "Don't foget remove task from root cron!"

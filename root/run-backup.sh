#!/bin/bash

##########################################################
#
#    /
#    ├── root
#    │   ├── backup
#    │   │   └── project-name
#    │   │       ├── .env.local
#    │   │       ├── ln -> .env
#    │   │       ├── ln -> run-backup.sh
#    │   │       └── ln -> google-api.sh
#    │   └── scripts
#    │       ├── .env
#    │       ├── ln -> run-backup.sh
#    │       ├── ln -> google-api.sh
#    │       ├── ln -> telegram-message.sh
#    │       └── ln -> telegram-message.sh
#    └── home
#        ├── sudo_user
#        │   └── proxy-backup
#        │       ├── sudo
#        │       │   ├── 00-adduser.sh
#        │       │   └── 88-deluser.sh
#        │       └── root
#        │           ├── google-api.sh
#        │           ├── run-backup.sh
#        │           ├── telegram-message.sh
#        │           └── telegram-message.sh
#        └── project-name
#            └── backup
#                ├── backup.file1
#                ├── backup.file2
#                └── .temp-flag
#                    └── delete.file
#
##########################################################

source .env.local

# Enter to running directory
cd /home/$USER_NAME/backup/

# Check upload flag-file. Only if file exist
if [ -f .temp-flag/delete.* ]; then
    rm .temp-flag/delete*

    # Get file names
    FILES_LIST="$(find . -type f | sed 's/^\.\///g')"

    # Google upload
    cd /root/backup/$USER_NAME/
    . ./google-api.sh

    # Send telegram message
    HOSTNAME=$(hostname)
    . ./telegram-message.sh

    # Remove backup
    cd /home/$USER_NAME/backup/
    rm *
    cd -
fi

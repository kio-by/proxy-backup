#!/bin/bash

# export variables
# source .env
# source .env.local

# Send telegram message
HOSTNAME=$(hostname)
TELEGRAM_MESSAGE="<b>🎯 $HOSTNAME на связи</b>\n\nBackUp is done for <b>$USER_NAME</b>\n<code>$FILES_LIST</code>"

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

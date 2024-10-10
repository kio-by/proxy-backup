#!/bin/bash

# export variables
cd /root/backup/scripts
source .env

# Get ACCESS TOKEN
BEARER=$(echo curl --silent \
    -d client_id=$CLIENT_ID \
    -d client_secret=$CLIENT_SECRET \
    -d refresh_token=$REFRESH_TOKEN \
    -d grant_type=refresh_token \
    https://accounts.google.com/o/oauth2/token)

ACCESS_TOKEN=$($BEARER | jq -r '.access_token')

#### Get and create folders on google drive ####
# https://developers.google.com/drive/api/guides/search-files
#
# Searh a folder typed "Google folder" into folder 'backup' with $USER_NAMEwith
#
#  Example:
#  https://www.googleapis.com/drive/v3/files?q=mimeType+%3d+%27application/vnd.google-apps.folder'%27+and+name+%3d+%27project_name%27+and+%271nU06cZFUfxKOVJZXkMFYl1noAozMdims%27+in+parents&supportsAllDrives=true&supportsAllDrives=true
#
##########################################################

google_space='+%3d+'
google_quote='%27'
google_mime_type='application/vnd.google-apps.folder'

search_project=$(
    curl --silent -G \
        "https://www.googleapis.com/drive/v3/files" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H 'Accept: application/json' \
        -d "supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" \
        -d "includeItemsFromAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" \
        -d "q=mimeType$google_space$google_quote$google_mime_type$google_quote+and+name$google_space$google_quote$USER_NAME$google_quote+and+$google_quote$GOOGLE_PARENT_FOLDER_ID$google_quote+in+parents+and+trashed$google_space+false" \
        --write-out "%{http_code}"
    # --verbose
)
project_id=$(jq -r -n "input | .files[].id" <<<$search_project)

current_year=($(date +"%Y"))

if [ -n "$project_id" ]; then
    search_project_year_folder=$(
        curl -s -G \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H 'Accept: application/json' \
            -d "supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" \
            -d "includeItemsFromAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" \
            -d "q=mimeType$google_space$google_quote$google_mime_type$google_quote+and+name$google_space$google_quote$current_year$google_quote+and+$google_quote$project_id$google_quote+in+parents+and+trashed$google_space+false" \
            --write-out "%{http_code}" \
            "https://www.googleapis.com/drive/v3/files"
    )
    year_folder_id=$(jq -r -n "input | .files[].id" <<<"$search_project_year_folder")
    if [ -z "$year_folder_id" ]; then
        year_folder_id=$(curl -s -X POST \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{
    'name': '$current_year',
    'mimeType': 'application/vnd.google-apps.folder',
    'parents': ['$project_id']
  }" \
            "https://www.googleapis.com/drive/v3/files?supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" | jq -r '.id')
    fi
else
    # Create parent folder and capture the folder ID
    parent_project_folder_id=$(curl -s -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
    'name': '$USER_NAME',
    'mimeType': 'application/vnd.google-apps.folder',
    'parents': ['$GOOGLE_PARENT_FOLDER_ID']
  }" \
        "https://www.googleapis.com/drive/v3/files?supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" | jq -r '.id')

    # Create child folder (current year) inside the parent folders
    year_folder_id=$(curl -s -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
    'name': '$current_year',
    'mimeType': 'application/vnd.google-apps.folder',
    'parents': ['$parent_project_folder_id']
  }" \
        "https://www.googleapis.com/drive/v3/files?supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES" | jq -r '.id')

fi

#### Upload files
# There are three types of uploads you can perform:
#
# Simple upload (uploadType=media): Use this upload type to transfer a small media file (5 MB or less) without
# supplying metadata. To perform a simple upload, refer to Perform a simple upload.
#
# Multipart upload (uploadType=multipart): "Use this upload type to transfer a small file
# (5 MB or less) along with metadata that describes the file, in a single request. To
# perform a multipart upload, refer to Perform a multipart upload.
#
# Resumable upload (uploadType=resumable): Use this upload type for large files (greater than
# 5 MB) and when there's a high chance of network interruption, such as when creating a file
# from a mobile app. Resumable uploads are also a good choice for most applications because they also work
# for small files at a minimal cost of one additional HTTP request per upload. To perform a resumable upload,
# refer to Perform a resumable upload.
#

# Getting file list

FILE_PATH="/home/$USER_NAME/backup/"
FILE_NAMES=($(sudo ls $FILE_PATH))

for FILE in "${FILE_NAMES[@]}"; do
    curl -X POST -L \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -F "metadata={ \
            name : '$FILE', \
           parents : ['$year_folder_id'] \
       }; \
       type=application/json;charset=UTF-8" \
        -F "file=@$FILE_PATH$FILE" \
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=$GOOGLE_SUPPORT_ALL_DRIVES"
done

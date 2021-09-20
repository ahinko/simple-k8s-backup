#!/bin/bash

set -o nounset

# Calculate some variables
EXCLUDE_ARGS=${EXCLUDE_ARGS:-""}
FORCE_RESTORE=${FORCE_RESTORE:-0}
RESTORE_FILE="${RESTORE_FILE:-latest.tgz}"
LOCAL_PATH="/${BACKUP_NAME}"
BACKUP_FILE=${BACKUP_NAME}-$(date +%Y%m%d_%H%M%S).tgz
LATEST_FILE="latest.tgz"

BUCKET=${MINIO_BUCKET}/${BACKUP_NAME}

# Do he actual backup and send the file to external storage
backup () {
    echo "Creating backup of ${LOCAL_PATH}"

    # Archive everything in the local path. Use EXCLUDE_ARGS to exclude
    # anything that should be ignored by the backup.
    set +e
    tar "${EXCLUDE_ARGS}" -zcf "/${BACKUP_FILE}" -C ${LOCAL_PATH} .

    exitcode=$?

    if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
        exit $exitcode
    fi
    set -e

    # Where should the file be stored
    resource="/${BUCKET}/${BACKUP_FILE}"

    # Set content type
    content_type="application/octet-stream"

    # Get current date
    date=$(date -R)

    # Prepare signature
    _signature="PUT\n\n${content_type}\n${date}\n${resource}"
    signature=$(echo -en "${_signature}" | openssl sha1 -hmac "${MINIO_SECRET_KEY}" -binary | base64)

    # Upload timestamped file to Minio/S3
    curl -k -v -X PUT -T "/${BACKUP_FILE}" \
        -H "Host: $MINIO_ENDPOINT" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${MINIO_ACCESS_KEY}:${signature}" \
            "https://$MINIO_ENDPOINT${resource}"

    # Also upload file as lastest.*
    resource="/${BUCKET}/${LATEST_FILE}"

   # Prepare signature
    _signature="PUT\n\n${content_type}\n${date}\n${resource}"
    signature=$(echo -en "${_signature}" | openssl sha1 -hmac "${MINIO_SECRET_KEY}" -binary | base64)

    # Upload timestamped file to Minio/S3
    curl -k -v -X PUT -T "/${BACKUP_FILE}" \
        -H "Host: $MINIO_ENDPOINT" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${MINIO_ACCESS_KEY}:${signature}" \
            "https://$MINIO_ENDPOINT${resource}"

    rm "/${BACKUP_FILE}"
}

restore () {
    echo "Restoring ${RESTORE_FILE} to ${LOCAL_PATH}"

    # Where should the file be downloaded from
    resource="/${BUCKET}/${RESTORE_FILE}"

    # Set content type
    content_type="text/plain"

    # Get current date
    date=$(date -R)

    # Prepare signature
    _signature="HEAD\n\n${content_type}\n${date}\n${resource}"
    signature=$(echo -en "${_signature}" | openssl sha1 -hmac "${MINIO_SECRET_KEY}" -binary | base64)

    # Check if the file exists and can be downloaded
    if curl --head --fail --silent \
        -H "Host: $MINIO_ENDPOINT" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${MINIO_ACCESS_KEY}:${signature}" \
            "https://$MINIO_ENDPOINT${resource}"
    then
        # File exists so lets download and restore it
        _signature="GET\n\n${content_type}\n${date}\n${resource}"
        signature=$(echo -en "${_signature}" | openssl sha1 -hmac "${MINIO_SECRET_KEY}" -binary | base64)

        # Download file from Minio/S3
        curl -k -v -X GET --output "${RESTORE_FILE}" \
            -H "Host: $MINIO_ENDPOINT" \
            -H "Date: ${date}" \
            -H "Content-Type: ${content_type}" \
            -H "Authorization: AWS ${MINIO_ACCESS_KEY}:${signature}" \
                "https://$MINIO_ENDPOINT${resource}"

        # Remove all old files before restoring
        rm -rf ${LOCAL_PATH}/*

        # Extract archive to provided path
        tar -zxvf ${RESTORE_FILE} -C ${LOCAL_PATH}

        # Delete the downloaded file
        rm -rf "${RESTORE_FILE}"
    else
        echo "File does not exist and can't therefor be downloaded and restored. Exiting..."
        exit 1
    fi
}

# Make sure that the local path actually exists. If it does not then something is wrong.
# We can't just create the missing directory since it should already be mounted in to the container.
if [ ! -d ${LOCAL_PATH} ]; then
    echo "${LOCAL_PATH} does not exist. Aborting.";
    exit 1;
fi

if [ "${FORCE_RESTORE}" == 1 ]; then
    restore
    exit 0
fi

# Check if the local folder is empty or not.
if [ -z "$(ls -A ${LOCAL_PATH})" ]; then
    # If it's empty, then we should restore a backup
    restore
else
    # If it isn't empty then we should do a backup
    backup
fi

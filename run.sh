#!/bin/bash

set -o nounset

# Backup options
EXCLUDE=${EXCLUDE:-""}
DELETE_OLDER_THAN=${DELETE_OLDER_THAN:-"30d"}

# Restore options
FORCE_RESTORE=${FORCE_RESTORE:-0}
RESTORE_FILENAME="${RESTORE_FILENAME:-latest.tgz}"

# Calculate some paths
LOCAL_PATH="./${BACKUP_NAME}"
BACKUP_FILENAME=${BACKUP_NAME}-$(date +%Y%m%d_%H%M%S).tgz
LATEST_FILENAME="latest.tgz"

# Convert exclude parameter to tar args
EXCLUDE_ARGS=""
if [ -z "$EXCLUDE" ]; then
    EXCLUDE_ARGS="--exclude ${EXCLUDE// / --exclude }"
fi

# Configure minio cli
mc alias set minio ${MINIO_HOST} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}

# Check if we can connect to the minio server
mc admin info minio &>/dev/null
if [ $? != 0 ] ; then
    echo "Could not connect to minio server."
    exit 1;
fi

# Make sure bucket exists
mc mb --ignore-existing minio/${MINIO_BUCKET}

backup () {
    echo "Creating backup of ${LOCAL_PATH}"

    # Archive everything in the local path. Use EXCLUDE_ARGS to exclude
    # anything that should be ignored by the backup.
    set +e
    tar ${EXCLUDE_ARGS} -zcf "./${BACKUP_FILENAME}" -C ${LOCAL_PATH} .

    exitcode=$?

    if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
        exit $exitcode
    fi
    set -e

    mc cp "./${BACKUP_FILENAME}" minio/${MINIO_BUCKET}/${BACKUP_NAME}/${BACKUP_FILENAME}
    if [ $? != 0 ] ; then
        echo "Failed to upload timestamped backup"
        exit 1;
    fi

    mc cp "./${BACKUP_FILENAME}" minio/${MINIO_BUCKET}/${BACKUP_NAME}/${LATEST_FILENAME}
    if [ $? != 0 ] ; then
        echo "Failed to upload latest backup"
        exit 1;
    fi

    rm "./${BACKUP_FILENAME}"

    mc rm -r --force --older-than ${DELETE_OLDER_THAN} minio/${MINIO_BUCKET}/${BACKUP_NAME}/
    if [ $? != 0 ] ; then
        echo "Failed to delete old backups"
        exit 1;
    fi
}

restore () {
    echo "Restoring ${RESTORE_FILENAME} to ${LOCAL_PATH}"

    mc cp minio/${MINIO_BUCKET}/${BACKUP_NAME}/${RESTORE_FILENAME} ./${RESTORE_FILENAME}

    # Remove all old files before restoring
    rm -rf ${LOCAL_PATH}/*

    # Extract archive to provided path
    tar -zxvf ${RESTORE_FILENAME} -C ${LOCAL_PATH}

    # Delete the downloaded file
    rm -rf "${RESTORE_FILENAME}"
}

# Make sure that the local path actually exists. If it does not then something is wrong.
# We can't just create the missing directory since it should already be mounted in to the container.
if [ ! -d ${LOCAL_PATH} ]; then
    echo "${LOCAL_PATH} does not exist. Aborting.";
    exit 1;
fi

if [ "${FORCE_RESTORE}" == 1 ]; then
    echo "Force restore"
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

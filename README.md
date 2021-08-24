# simple-k8s-backup

A simple Docker container for backing up and restoring folders from within the container. **I take no responsibility so use this at your own risk.**

My use case:

* I have `persistent volumes` with RWX access mode in my Kubernetes cluster. This gives me the option to mount the volume to multiple pods.

How the backup script in the container works:

* `LOCAL_PATH` is the same as `/BACKUP_NAME` and can not be set using an environment variable
* The container starts and uses the `LOCAL_PATH` so any persistent volumes needs to be mounted to `LOCAL_PATH`.
* It checks if the `LOCAL_PATH` exists and if the directory is empty or not.
  * If the directory contains something it will create an archive of all the content in the directory and then upload it to `MINIO_BUCKET/BACKUP_NAME`. It will upload to files:
    * One with a timestamp in the file name (`BACKUP_NAME`-current_date_time.tgz)
    * and one file named `latest.tgz`
  * If the directory was empty it will either download `latest.tgz` or `RESTORE_FILE` (if specified) and restore it to `LOCAL_PATH`
* It's also possible to force a restore by setting `FORCE_RESTORE` to `1`

## Enviroment variables

* `BACKUP_NAME` Filename used by the backup process to name the archived file. Example: "home-assistant". The script will add the current date and time to the filename. (backup only)

* `MINIO_ACCESS_KEY`

* `MINIO_SECRET_KEY`

* `MINIO_ENDPOINT` Hostname and port (if needed). Example: minio.local.dev:9000

* `MINIO_BUCKET` Bucket name. A subfolder based on `BACKUP_NAME` will be created. Example: backup/home-assistant

* `RESTORE_FILE` The filename of the backup file that should be downloaded and restored. (restore only)

* `FORCE_RESTORE` Set to 1 to force a restore (restore only)

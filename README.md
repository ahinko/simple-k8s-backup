# simple-k8s-backup

A simple Docker container for backing up and restoring folders from within the container to a Minio server. This script is highly opinionated and tailored for my needs. **I take no responsibility so use this at your own risk.**

How the backup script in the container works:

* The environment variable `BACKUP_NAME` is used to determine where the script will look for files to backup. `LOCAL_PATH` is the same as `/BACKUP_NAME` and `LOCAL_PATH` can not be changed or set using an environment variable
* The container starts and uses the `LOCAL_PATH` so any persistent volumes needs to be mounted to `LOCAL_PATH`.
* It checks if the `LOCAL_PATH` exists and if the directory is empty or not.
  * If the directory contains something it will create an archive of all the content in the directory and then upload it to `MINIO_BUCKET/BACKUP_NAME`. It will upload two files:
    * One with a timestamp in the file name (`BACKUP_NAME`-current_date_time.tgz)
    * and one file named `latest.tgz`
  * If the directory was empty it will either download `latest.tgz` or `RESTORE_FILENAME` (if specified) and restore it to `LOCAL_PATH`
* It's also possible to force a restore by setting `FORCE_RESTORE` to `1`

## Enviroment variables

* `TZ` Set timezone

* `BACKUP_NAME` Filename used by the backup process to name the archived file. Example: "home-assistant". The script will add the current date and time to the filename. (backup only)

* `MINIO_ACCESS_KEY`

* `MINIO_SECRET_KEY`

* `MINIO_HOST` Hostname and port (if needed). Example: minio.local.dev:9000

* `MINIO_BUCKET` Bucket name (must be lowercase). A subfolder based on `BACKUP_NAME` will be created. So setting `MINIO_BUCKET` to `backup` and `BACKUP_NAME` to `home-assistant` would upload the backup to `backup/home-assistant`

* `EXCLUDE` can be used to exclude files or directories from the backup. Must be written as a space separated string. Example: `./sqlite.db ./.vscode`

* `DELETE_OLDER_THAN` determines how long files should be stored. On each backup files older than this value will be deleted. Defaults to: 30d

* `RESTORE_FILENAME` The filename of the backup file that should be downloaded and restored. (restore only)

* `FORCE_RESTORE` Set to 1 to force a restore (restore only)

* `HEALTHCHECK_URL` An URL that should be called after a backup has completed successfully

## Example
Here is an example setting up a cronjob in Kubernetes:

```yaml
---

apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-home-assistant
  namespace: home-automation
spec:
  schedule: "0 8 * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          initContainers:
            - name: sleep
              image: ghcr.io/ahinko/simple-k8s-backup:latest
              command: ["/sleep.sh"]
              args: ["1", "900"]
          containers:
            - name: backup
              image: ghcr.io/ahinko/simple-k8s-backup:latest
              args:
                - /run.sh
              env:
                - name: TZ
                  value: "UTC"
                - name: MINIO_ACCESS_KEY
                  value: "some-access-key"
                - name: MINIO_SECRET_KEY
                  value: "the-secret-key"
                - name: MINIO_HOST
                  value: "minio.local.dev"
                - name: MINIO_BUCKET
                  value: "backup"
                - name: BACKUP_NAME
                  value: "home-assistant"
                - name: DELETE_OLDER_THAN
                  value: "30d"
                - name: EXCLUDE
                  value: "./home-assistant_v2.db ./core"
                - name: HEALTHCHECK_URL
                  value: "https://url.to.ping"
              volumeMounts:
                - name: home-assistant-persistent-storage
                  mountPath: /home-assistant
          restartPolicy: OnFailure
          volumes:
            - name: home-assistant-persistent-storage
              persistentVolumeClaim:
                claimName: home-assistant-config
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                      - key: app.kubernetes.io/name
                        operator: In
                        values:
                          - home-assistant
                  topologyKey: kubernetes.io/hostname
```

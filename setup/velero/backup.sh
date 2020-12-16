#!/usr/bin/env bash
set -eo pipefail

# Backup details
BACKUP_NAME="delivery-training-velero-backup-$(date +'%Y%m%d-%H%M%S')"
BACKUP_DIR="${HOME}/kind-backups/"
mkdir -p ${BACKUP_DIR}

# Backup cluster with Velero into Minio
velero backup create ${BACKUP_NAME} --snapshot-volumes=false --exclude-resources jobs,pods --wait

# Download backup from Minio
function mc() {
    docker run -it --net=host -e MC_HOST_velero-backup=http://minio:minio123@172.18.255.1:9000 -v $(pwd):/app -w /app minio/mc "$@"
}
mc ls velero-backup
mc cp -r velero-backup/velero/backups/${BACKUP_NAME}/ ${BACKUP_NAME}
sudo chown -R ${USERNAME}: ${BACKUP_NAME}
mv ${BACKUP_NAME}/ ${BACKUP_DIR}

echo
echo "------------------------------------------------------------------------------"
echo "A backup of your cluster (${BACKUP_NAME}) is available in '${BACKUP_DIR}' :"
echo "------------------------------------------------------------------------------"
echo 
ls -lrt ${BACKUP_DIR}
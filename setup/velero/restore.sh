#!/usr/bin/env bash
set -eo pipefail

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BACKUP_PATH=$1

[[ -z $BACKUP_PATH ]] && { echo "You must specify the backup directory to restore in argument."; exit 1; }

export MINIO_IP=$(kubectl -n velero get service minio -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export MINIO_PORT=$(kubectl -n velero get service minio -o jsonpath='{.spec.ports[0].port}')

# Minio CLI
function mc() {
    docker run -it --net=host -e MC_HOST_velero-backup=http://minio:minio123@${MINIO_IP}:${MINIO_PORT} -v ${DIR}:/app -w /app minio/mc "$@"
}

# Copy backup in the current directory (because only current dir is bind-mounted by docker command above)
BACKUP_NAME=$(basename ${BACKUP_PATH})
rm -rf ${DIR}/${BACKUP_NAME}
cp -r ${BACKUP_PATH} ${DIR}

# Load backup directory into Minio
mc cp -r ${BACKUP_NAME} velero-backup/velero/backups/ 

echo "Waiting for velero to discover backup in Minio..."
until velero backup get ${BACKUP_NAME} 2>/dev/null; do 
    echo "."
    sleep 2
done

echo "Backup ready : restorating with Velero..."

# Restore cluster state from Velero backup
velero restore create --from-backup ${BACKUP_NAME} --wait

# Clean local directory
rm -rf ${DIR:?}/${BACKUP_NAME}
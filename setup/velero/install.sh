#!/usr/bin/env bash
set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install Minio
echo "---------------------------------------------------"
echo "Installing Minio..."
echo "---------------------------------------------------"
kubectl apply -f https://raw.githubusercontent.com/vmware-tanzu/velero/main/examples/minio/00-minio-deployment.yaml --force
echo "Patching minio service..."
kubectl patch svc minio -p '{"spec":{"type":"LoadBalancer"}}' -n velero
sleep 5
MINIO_IP=$(kubectl -n velero get service minio -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
MINIO_PORT=$(kubectl -n velero get service minio -o jsonpath='{.spec.ports[0].port}')
echo
echo "---------------------------------------------------"
echo "Minio available at http://${MINIO_IP}:${MINIO_PORT}"
echo "---------------------------------------------------"
echo

# Install Velero CLI
if ! command -v velero >/dev/null; then
    echo "---------------------------------------------------"
    echo "Installing Velero CLI..."
    echo "---------------------------------------------------"
    VELERO_VERSION="1.5.2"
    wget https://github.com/heptio/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
    tar zxvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
    rm -f velero-v${VELERO_VERSION}-linux-amd64.tar.gz
    sudo mv velero-*/velero /usr/local/bin
    rm -rf velero-*
    sudo chmod +x /usr/local/bin/velero

fi
echo "Velero CLI is installed :" 
velero version --client-only
echo

# Install Velero
 velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.0 \
    --bucket velero \
    --secret-file ${DIR}/credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000 \
    --wait
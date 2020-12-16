# Delivery using [Flux](https://toolkit.fluxcd.io/get-started/)

## Install Flux

### Install CLI

```
curl -s https://toolkit.fluxcd.io/install.sh | sudo bash
flux --version
```

### Bootstrap Flux into the cluster

- Check you cluster :

```
flux check --pre
```

- Create a personnal access token in your github account : https://github.com/settings/tokens

```
export GITHUB_USER=<your_username>
export GITHUB_TOKEN=<your_access_token>
export GITHUB_REPO="podtato-head-flux"
```

- Bootstrap flux with your github repository details :

```
flux bootstrap github \
  --owner="${GITHUB_USER}" \
  --repository=podtato-head-flux \
  --branch=main \
  --path=delivery/manifest \
  --personal
```

The bootstrap command creates a repository if one doesn't exist, and commits the manifests for the Flux components to the default branch at the specified path. Then it configures the target cluster to synchronize with the specified path inside the repository.

- Check installation

```
flux check
```

- Clone the repository :

```
git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}
cd ${GITHUB_REPO}
```

- Create a git source pointing to a public repository master branch:

```
flux create source git webapp \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=30s \
  --export > ./delivery/manifest/webapp-source.yaml
```

- Create a kustomization for synchronizing the common manifests on the cluster:

```
flux create kustomization webapp-common \
  --source=webapp \
  --path="./deploy/webapp/common" \
  --prune=true \
  --validation=client \
  --interval=1h \
  --export > ./delivery/manifest/webapp-common.yaml
```

- Create a kustomization for the backend service that depends on common:

```
flux create kustomization webapp-backend \
  --depends-on=webapp-common \
  --source=webapp \
  --path="./deploy/webapp/backend" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/backend.webapp" \
  --health-check-timeout=2m \
  --export > ./delivery/manifest/webapp-backend.yaml
```

- Create a kustomization for the frontend service that depends on backend:

```
flux create kustomization webapp-frontend \                                               
  --depends-on=webapp-backend \
  --source=webapp \
  --path="./deploy/webapp/frontend" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/frontend.webapp" \
  --health-check-timeout=2m \
  --export > ./delivery/manifest/webapp-frontend.yaml
```

- Push changes to origin:

```
git add -A && git commit -m "add webapp" && git push
```
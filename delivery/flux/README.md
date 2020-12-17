# Delivery using [Flux](https://toolkit.fluxcd.io/get-started/)

_NOTE : you have to be into `delivery/flux` folder to run the commands below._

## Install Flux

### Install CLI

```
./setup/install.sh
```

### Install Flux resoures into cluster

Check you cluster :

```
flux check --pre
```

To keep things simple for now, we install Flux in "dev" mode :

```
flux install --arch=amd64

# Note: Flux can also be installed using kubectl
# kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

_Note: In production, it is recommended to use the `bootstrap` mode to ensure the Flux manifests are also synched with a GIT repository._
_cf. "Bootstrap Flux into the cluster" at the end of this file._

### Check install

```
flux check
```

## Register Git repositories and reconcile them on your cluster

- [Create a git source](https://toolkit.fluxcd.io/cmd/flux_create_source_git/) pointing to a repository main branch:

```
# Replace by your username to point to YOUR fork of the "podtatohead" project
export GITHUB_USER="yogeek" 

flux create source git podtato \
  --url="https://github.com/${GITHUB_USER}/podtato-head" \
  --branch="main" \
  --interval=1m
```

A `GitRepository` Custom Resource has been created:
```
kubectl get gitrepositories.source.toolkit.fluxcd.io -n flux-system
```

- [Create a kustomization](https://toolkit.fluxcd.io/cmd/flux_create_kustomization/) for synchronizing manifests on the cluster:

```
flux create kustomization podtato \
  --source=podtato \
  --path="./delivery/manifest" \
  --prune=true \
  --validation=client \
  --health-check="Deployment/podtatohead.demospace" \
  --health-check-timeout=2m
```

A `Kustomization` Custom Resource has been created:
```
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n flux-system
```

- In about 30s the synchronization should start:

```
watch flux get kustomizations
```

- When the synchronization finishes you can check that the webapp services are running:

```
kubectl -n demospace get deployments,services
```

You can see you app with its service IP (or with port-forward if you do have a load-balancer):

```
SVC_IP=$(kubectl -n demospace get service podtatohead -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SVC_PORT=$(kubectl -n demospace get service podtatohead -o jsonpath='{.spec.ports[0].port}')
xdg-open http://${SVC_IP}:${SVC_PORT}
```

From now, any changes made to the Kubernetes manifests in the main branch will be synchronised with the cluster !

- Try to update your source code :

```
# vim ../manifest/manifest.yaml
# Update the image version (reminder: existing tags are 0.1.0, 0.1.1, 0.1.2)

# Commit and push your modification
git add -A && git commit -m "update app" && git push 
```

Observe Flux synching your modifications directly into the cluster:

```
watch flux get kustomizations
```

Refresh you app page in the browser !

**Note**: Even if it is easier to use `flux create` to deploy all Flux objects, the best practice is of course to store the YAML corresponding to these resources in GIT.
To see the manifest for each object, you can use `--export` option or also use the `flux export` command on an existing resource :

```
flux create source git podtato \
  --url="https://github.com/${GITHUB_USER}/podtato-head" \
  --branch="main" \
  --interval=1m \
  --export

flux export source git podtato
```

You can see the resulting files in `./flux-cr/kustomization/` directory.

## Reconciliation details

IMPORTANT :

1. If a Kubernetes manifest is removed from the repository, the reconciler will remove it from your cluster.
2. If you alter the deployment using `kubectl edit`, the changes will be reverted to match the state described in git.
3. If you delete a Kustomization, the reconciler will remove all Kubernetes objects.

## Delete kustomization and source

- Delete the kustomization and see what happens to your resources:

```
flux delete kustomization podtato
```

- Delete the git source :

```
flux delete source git podtato
```

## Register Helm repositories and create Helm releases

https://toolkit.fluxcd.io/guides/helmreleases/

To be able to release a Helm chart, the source that contains the chart (either a HelmRepository, GitRepository, or Bucket) has to be known first to the [source-controller](https://toolkit.fluxcd.io/components/source/controller/), so that the HelmRelease can reference to it.

## Helm release from HelmRepository

```
flux create source helm bitnami \
  --interval=1h \
  --url=https://charts.bitnami.com/bitnami

flux create helmrelease nginx \
  --interval=1h \
  --release-name=nginx \
  --target-namespace=default \
  --source=HelmRepository/bitnami \
  --chart=nginx \
  --chart-version="8.x.x"
```

You now have deployed the `bitnami/nginx` helm chart from the bitnami helm repository.

```
helm ls
```

Check the nginx service :
```
SVC_IP=$(kubectl -n default get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')  
SVC_PORT=$(kubectl -n default get service nginx -o jsonpath='{.spec.ports[0].port}')  
xdg-open http://${SVC_IP}:${SVC_PORT}
```

Delete the resources:

```
flux delete helmrelease nginx
flux delete source helm bitnami
```

## Helm release from GitRepository

In our case, the chart is in a Git repo, so we can register a GitRepository source like this :

```
kubectl apply -f ./flux-cr/helm/podtato-chart-gitrepository.yaml
```

And then define a new HelmRelease to release the Helm chart:

```
kubectl apply -f ./flux-cr/helm/podtato-helmrelease.yaml
```

The [helm-controller](https://toolkit.fluxcd.io/components/helm/controller/) will then create a new HelmChart resource in the same namespace as the sourceRef.

You can check the resulting Custom Resources:

```
kubectl get gitrepository.source.toolkit.fluxcd.io,helmrelease.helm.toolkit.fluxcd.io,helmcharts.source.toolkit.fluxcd.io -A
```

### Bootstrap Flux into the cluster

FLux itself should be deployed from a git repository to respect GitOps principles.
To achieve this, Flux has a `boostrap` command.

- Check you cluster :

```
flux check --pre
```

- Create a personnal access token in your github account : https://github.com/settings/tokens

```
export GITHUB_USER=<your_username>
export GITHUB_TOKEN=<your_access_token>
export GITHUB_REPO="podtatohead-flux"
```

- Bootstrap flux with your github repository details :

```
flux bootstrap github \
  --owner="${GITHUB_USER}" \
  --repository=${GITHUB_REPO} \
  --branch=main \
  --path=manifests/flux \
  --personal
```

The bootstrap command creates a repository if one doesn't exist, and commits the manifests for the Flux components to the default branch at the specified path. Then it configures the target cluster to synchronize with the specified path inside the repository.

- Check installation

```
flux check
```

## Podinfo app

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
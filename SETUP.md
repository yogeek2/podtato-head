# Setup a local environment

## Fork the repository

Fork the https://github.com/yogeek2/podtato-head/ in your GitHub account.

Replace all "yogeek2" occurencces by your github username.
Either your IDE "find/replace all" feature or a sed :

```
export GITHUB_USER=toto
find . -type f -not -path "./.git/*" | xargs grep -l yogeek2 | xargs sed -i 's/yogeek2/'"$GITHUB_USER"'/g'
```

Commit and push

```
git add -A && git commit "init repo" && git push origin master
```

## Build images locally

```
cd podtato-head
./buildPush.sh
```

If you do not have a dockerhub account : open one ! ;P 
Iy you do not want to, you can only build the images and you will have to load them into your kind cluster in the next section :

```
cd podtato-head
./build.sh
```

## Local K8S cluster

- Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) :

```
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

- Create a kind cluster :

```
kind create cluster
```

Your current terminal is automatically configured to point to your kind cluster.
If you use other terminals, do not forget to configure your KUBECONFIG environment variable :
```
export KUBECONFIG=$HOME/.kind/config
```

- Check cluster :

```
kubectl cluster-info
```

- If images have only been built locally (not pushed to dockerhub), load them into your kind cluster :

```
export GITHUB_USER=toto
kind load docker-image ${GITHUB_USER}/podtatohead:v0.1.0
kind load docker-image ${GITHUB_USER}/podtatohead:v0.1.1
kind load docker-image ${GITHUB_USER}/podtatohead:v0.1.2
```

## Get LoadBalancer feature with kind+MetalLB (only for Linux users)

Kubernetes on kind (like in bare metal) doesn’t come with an easy integration for things like services of type LoadBalancer.
This mechanism is used to expose services inside the cluster using an external Load Balancing mechansim that understands how to route traffic down to the pods defined by that service.

To achieve a similar feature, [MetalLB](https://metallb.universe.tf/installation/) can be used.

```
./setup/metal-lb/install.sh
```

Now, every `LoadBalancer` service will have an external IP assigned automatically and will be available at this IP.

## Istio + addons (prometheus, kiali...)

Istio is used by progessive delivery tools (Flagger, Argo Rollouts...).

```
./setup/istio/install.sh
./setup/istio/addons.sh
```

## Local tools

```
# Helm 3
./setup/charts/setup/install.sh

# Kustomize
./setup/kustomize/setup/install.sh

# Kapp
./setup/kapp/setup/install.sh
```

## Useful tools

- Install [kubefwd](https://github.com/txn2/kubefwd) to easily port forward K8S services.

```
curl https://i.jpillora.com/txn2/kubefwd! | sudo bash
kubefwd version
```

## MAGIC SHORTCUT : Load preconfigured cluster from backup

Ask for the backup to the trainer and use it to restore a pre-configured cluster:
(The metallb step is needed to run the following command in a local cluster)

```
./setup/velero/install.sh
./setup/velero/restore.sh <BACKUP_PATH>
```
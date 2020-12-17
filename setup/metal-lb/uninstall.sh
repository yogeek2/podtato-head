#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# https://mauilion.dev/posts/kind-metallb/?s=03

envsubst < ${DIR}/config.yaml | kubectl delete -f -
kubectl delete secret -n metallb-system memberlist 
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml

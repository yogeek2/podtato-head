#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# https://mauilion.dev/posts/kind-metallb/?s=03

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 

# Install Metal LB (https://metallb.universe.tf/installation/#installation-with-kustomize)
# kustomize build . | kubectl delete -f -

sleep 10

# Find docker 'kind' network CIDR 
# (normally is "172.18.0.0/16")
kind_subnet=$(docker network inspect kind | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
first_ip=${kind_subnet/0.0\/16/255.1}
last_ip=${kind_subnet/0.0\/16/255.250}


# => We swipe the last 10 ip addresses from that allocation and use them for the metallb configuration.
export METALLB_IPS_RANGE=$first_ip-$last_ip

echo "MetalLB IP range = $METALLB_IPS_RANGE"

# Deploy Metal LB configuration (https://metallb.universe.tf/configuration/)
# The following configuration gives MetalLB control over IPs from 172.17.255.1 to 172.17.255.250, 
# and configures Layer 2 mode

envsubst < ${DIR}/config.yaml | kubectl apply -f -
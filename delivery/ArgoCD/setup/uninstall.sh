#!/usr/bin/env bash

echo "---------------------------------------------------"
echo "Uninstalling ArgoCD on your cluster :"
echo "---------------------------------------------------"

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd --ignore-not-found
#!/usr/bin/env bash

if ! command -v argocd >/dev/null; then
    echo "---------------------------------------------------"
    echo "Installing ArgoCD CLI..."
    echo "---------------------------------------------------"
    VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
    sudo chmod +x /usr/local/bin/argocd
fi

echo "$(argocd version --client --short) is installed."
echo

# https://argoproj.github.io/argo-cd/getting_started/#1-install-argo-cd
echo "---------------------------------------------------"
echo "Installing ArgoCD on your cluster :"
echo "---------------------------------------------------"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "---------------------------------------------------"

# Checking argo version (both client and server)
# kubectl port-forward svc/argocd-server 8080:80 > /dev/null &
# cur_pid=$!
# sleep 2 && echo && argocd version --short && echo
# kill $cur_pid

cat << EOF

Argo installation done !

You can connect to the UI with :

    kubectl port-forward svc/argocd-server 8080:80

You can authenticate with 'admin' user and the following password : 

    kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2

Please follow the rest of the documentation to:

- Expose your the ArgoCD UI : https://argoproj.github.io/argo-cd/getting_started/#3-access-the-argo-cd-api-server
- Get access by retrieving the password : https://argoproj.github.io/argo-cd/getting_started/#4-login-using-the-cli

Example to connect to the UI : kubectl port-forward svc/argocd-server 8080:80

EOF

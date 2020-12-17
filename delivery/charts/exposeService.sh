export POD_NAME=$(kubectl get pods --namespace podtato-helm -l "app.kubernetes.io/name=podtatohead,app.kubernetes.io/instance=ph" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace podtato-helm $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl --namespace podtato-helm port-forward $POD_NAME 8080:$CONTAINER_PORT

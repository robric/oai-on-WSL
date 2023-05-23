kubectl get nodes -o name | xargs -I {} kubectl label {} node-role.kubernetes.io/control-plane=true
kubectl create ns jcnr
kubectl apply -f jcnr-secrets.yaml
kubectl apply -f jcnr-config.yaml
kubectl apply -f jcnr-node-config.yaml
kubectl apply -f jcnr.yaml

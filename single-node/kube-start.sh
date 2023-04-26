kubeadm reset -f
kubeadm init --pod-network-cidr 10.244.0.0/16 
sleep 30 
export KUBECONFIG=/etc/kubernetes/admin.conf 
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- 
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

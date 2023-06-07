#!/bin/bash

sudo kubeadm init --pod-network-cidr 10.244.0.0/16
sleep 60

# Initializing kubeconfig file

sudo cp /etc/kubernetes/admin.conf .kube/config
chown -R ubuntu .kube/

# Untaint Master for scheduling

kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-

# CNI installation: flannel + multus

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml


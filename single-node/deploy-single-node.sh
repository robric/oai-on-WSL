#!/bin/bash

#deployment 5GC

cd oai-cn5g-fed/
kubectl create ns oai
cd charts/oai-5g-core/oai-5g-basic
helm dependency update
helm spray --namespace oai .

export AMF_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].metadata.name}")
export SMF_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-smf" -o jsonpath="{.items[0].metadata.name}")
export SPGWU_TINY_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-spgwu-tiny" -o jsonpath="{.items[0].metadata.name}")
export AMF_eth0_POD_IP=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].status.podIP}")


#deployment 5GRAN

cd ../../oai-5g-ran
helm install gnb oai-gnb --namespace oai

export GNB_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[0].metadata.name}")
export GNB_eth0_IP=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[*].status.podIP}")

kubectl logs -c amf $AMF_POD_NAME -n oai  | grep 'Sending NG_SETUP_RESPONSE Ok' 

sleep 10

helm install nrue oai-nr-ue/ --namespace oai
export NR_UE_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=nrue" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -it -n oai -c nr-ue $NR_UE_POD_NAME -- ifconfig oaitun_ue1 |grep -E '(^|\s)inet($|\s)' | awk {'print $2'}



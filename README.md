# Generic steps for OAI Deployment

## Background
Most information from this section is derived from https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_HC.md and links. 

Each NF is associated with a values.yaml file which stores parameters for the deployment.
Notably, there is a "config:" section with Networking and RAN parameters such an in the below example for a DU (note that some of these parameters should be controllable via O1 overtime):

```
config:
  mountConfig: false          #If config file is mounted then please edit mount.conf in configmap.yaml properly
  timeZone: "Europe/Paris"
  rfSimulator: "server"
  gnbduName: "oai-du-rfsim"
  useSaTDDcu: "yes"
  mcc: "001"   # check the information with AMF, SMF, UPF/SPGWU
  mnc: "01"    # check the information with AMF, SMF, UPF/SPGWU
  mncLength: "2" # check the information with AMF, SMF, UPF/SPGWU
  tac: "1"     # check the information with AMF
  nssaiSst: "1"  #currently only 4 standard values are allowed 1,2,3,4
  nssaiSd0: "ffffff"    #values in hexa-decimal format
  amfIpAddress: "oai-amf-svc"  # Not mandatory, you can leave it like this in coming release it will be removed
  gnbNgaIfName: "eth0"            # net1 in case multus create is true that means another interface is created for ngap interface, n2 to communi
cate with amf
  gnbNgaIpAddress: "status.podIP" # n2IPadd in case multus create is true
  gnbNguIfName: "eth0"   #net2 in case multus create is true gtu interface for upf/spgwu
  gnbNguIpAddress: "status.podIP" # n3IPadd in case multus create is true
  f1IfName: "eth0"                # net3 incase multus create is true
  f1cuIpAddress: "10.244.0.92"     # replace this value with GNB_CU_eth0_IP if not using multus
  f1duIpAddress: "status.podIP"
  f1cuPort: "2153"
  f1duPort: "2153"
  useAdditionalOptions: "--sa --rfsim --log_config.global_log_options level,nocolor,time"
```
## Single Cluster/Node

This is the simplest iteration with both 5GC and RAN running in a same Node/Cluster. There is no need for customization of networking since this is self-contained (i.e. AMF IP automatically retrieved within the cluster). For conveniency, a script named "deploy-single-node.sh" executes the commands detailed below.

- Deployment 5GC

The below process deploys the master branch. Dev branch is available through "git clone -b feat/helm-repo https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git". At time of writing, this branch has charts for ORAN gNB Split (CU-UP/CP and DU). 

```
### Dev branch: git clone -b feat/helm-repo https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git
git clone https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed
cd oai-cn5g-fed/
kubectl create ns oai-tutorial
cd charts/oai-5g-core/oai-5g-basic
helm dependency update
helm spray --namespace oai-tutorial .
```

After some time you get the 5GC core pods running
```console
ubuntu@ip-10-0-1-57:~/oai-cn5g-fed/charts/oai-5g-ran$ kubectl get pods -n oai-tutorial
NAME                              READY   STATUS    RESTARTS      AGE
mysql-795c8b8d7f-f6db8            1/1     Running   1 (28m ago)   85m
oai-amf-6ccd8654d8-z7jkf          2/2     Running   5 (25m ago)   84m
oai-ausf-87b7dfbd9-4lrvf          2/2     Running   5 (26m ago)   84m
oai-nrf-77677847d6-g7tvb          2/2     Running   2 (28m ago)   85m
oai-smf-6cb77d9844-vtsh2          2/2     Running   0             24m
oai-spgwu-tiny-78c7b4fc46-xwtxz   2/2     Running   0             24m
oai-udm-96b854bf9-9d5mf           2/2     Running   4 (26m ago)   84m
oai-udr-5c9cb57dd7-gxq5s          2/2     Running   2 (28m ago)   85m
```
Initialize a few env variables (Useful for Checking RAN)
```
export AMF_POD_NAME=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].metadata.name}")
export SMF_POD_NAME=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-smf" -o jsonpath="{.items[0].metadata.name}")
export SPGWU_TINY_POD_NAME=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-spgwu-tiny" -o jsonpath="{.items[0].metadata.name}")
export AMF_eth0_POD_IP=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].status.podIP}")
```

- Deployment 5GRAN

Just follow the steps below for the gNB Deployment

```
cd ../../oai-5g-ran
helm install gnb oai-gnb --namespace oai-tutorial
```
When the pod is running, check that it works (you should see the 'Sending NG_SETUP_RESPONSE Ok' message from the log (last line)
```
export GNB_POD_NAME=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[0].metadata.name}")
export GNB_eth0_IP=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[*].status.podIP}")

kubectl logs -c amf $AMF_POD_NAME -n oai-tutorial | grep 'Sending NG_SETUP_RESPONSE Ok' 
```

For UE emulation, again launch helm chart to deploy the UE emulation. 

```
helm install nrue oai-nr-ue/ --namespace oai-tutorial
```
After some time things should work, the last command gets you the UE IP address.

```console
ubuntu@ip-10-0-1-57:~/oai-cn5g-fed/charts/oai-5g-ran$ kubectl get pods -n oai-tutorial
NAME                              READY   STATUS    RESTARTS      AGE
mysql-795c8b8d7f-f6db8            1/1     Running   1 (43m ago)   100m
oai-amf-6ccd8654d8-z7jkf          2/2     Running   5 (40m ago)   99m
oai-ausf-87b7dfbd9-4lrvf          2/2     Running   5 (41m ago)   99m
oai-gnb-67f978678d-rjv7p          2/2     Running   0             22m
oai-nr-ue-647bd959f7-fd5hc        2/2     Running   0             17m
oai-nrf-77677847d6-g7tvb          2/2     Running   2 (43m ago)   100m
oai-smf-6cb77d9844-vtsh2          2/2     Running   0             39m
oai-spgwu-tiny-78c7b4fc46-xwtxz   2/2     Running   0             39m
oai-udm-96b854bf9-9d5mf           2/2     Running   4 (41m ago)   100m
oai-udr-5c9cb57dd7-gxq5s          2/2     Running   2 (43m ago)   100m

ubuntu@ip-10-0-1-57:~/oai-cn5g-fed/charts/oai-5g-ran$ export NR_UE_POD_NAME=$(kubectl get pods --namespace oai-tutorial -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=nrue" -o jsonpath="{.items[0].metadata.name}")

ubuntu@ip-10-0-1-57:~/oai-cn5g-fed/charts/oai-5g-ran$ kubectl exec -it -n oai-tutorial -c nr-ue $NR_UE_POD_NAME -- if
config oaitun_ue1 |grep -E '(^|\s)inet($|\s)' | awk {'print $2'}
12.1.1.100
```
Pings from a UE to internet just work fine.
```
ubuntu@ip-10-0-1-238:~$ kubectl exec -it oai-nr-ue-647bd959f7-58z5t -n oai -- ping -I oaitun_ue1  www.juniper.net
Defaulted container "nr-ue" out of: nr-ue, tcpdump
PING e1824.dscb.akamaiedge.net (104.84.54.246) from 12.1.1.100 oaitun_ue1: 56(84) bytes of data.
64 bytes from a104-84-54-246.deploy.static.akamaitechnologies.com (104.84.54.246): icmp_seq=1 ttl=42 time=113 ms
64 bytes from a104-84-54-246.deploy.static.akamaitechnologies.com (104.84.54.246): icmp_seq=2 ttl=42 time=352 ms
64 bytes from a104-84-54-246.deploy.static.akamaitechnologies.com (104.84.54.246): icmp_seq=3 ttl=42 time=94.4 ms
64 bytes from a104-84-54-246.deploy.static.akamaitechnologies.com (104.84.54.246): icmp_seq=4 ttl=43 time=164 ms
64 bytes from a104-84-54-246.deploy.static.akamaitechnologies.com (104.84.54.246): icmp_seq=5 ttl=43 time=224 ms
```

## Mod 1: add a second UE

First, don't even think of increasing replicas in the deployment: you need to modify a key -unique per UE- 5G parameters (IMSI).
In the sql db (https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/charts/oai-5g-core/mysql/initialization/oai_db-basic.sql), several IMSI are defined by default. A simple way is to copy the orginal charts and modify the values.

```
cd ~/oai-cn5g-fed/charts/oai-5g-ran/
mkdir oai-nr-ue2
cp -R oai-nr-ue/* oai-nr-ue2/
```
Make edits in the new folder (i.e. "oai-nr-ue2")
- edit values.yaml to configure a different IMSI for ue2 (e.g. '001010000000102')
- edit Chart.yaml and change de name (i.e. change the Chart name "oai-nr-ue" to "oai-nr-ue2")
Then apply the new chart
```
helm install nrue2 . -n oai
```
That should do the trick.
```
ubuntu@ip-10-0-1-238:~/oai-cn5g-fed/charts/oai-5g-ran/oai-nr-ue2$ kubectl get pods -A | grep ue
oai           oai-nr-ue-647bd959f7-58z5t         2/2     Running   10 (2m26s ago)   74m
oai           oai-nr-ue2-699455654c-xrw96        2/2     Running   6 (2m30s ago)    13m
```
UEs can ping each other (.100 is the address of nr-ue) !
```
ubuntu@ip-10-0-1-238:~$ kubectl exec -it oai-nr-ue2-699455654c-xrw96 -n oai sh
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
Defaulted container "nr-ue" out of: nr-ue, tcpdump
# ip addr
[...]
3: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 12.1.1.102/24 brd 12.1.1.255 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
# ping 12.1.1.100
PING 12.1.1.100 (12.1.1.100) 56(84) bytes of data.
64 bytes from 12.1.1.100: icmp_seq=1 ttl=64 time=220 ms
64 bytes from 12.1.1.100: icmp_seq=2 ttl=64 time=350 ms
64 bytes from 12.1.1.100: icmp_seq=3 ttl=64 time=245 ms
```

# OAI deployment in AWS

## Preparation

### (If not yet done) Install aws-cli -from scratch-

This is documented here:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

On Linux:
```
sudo apt-get install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Create an Access Key in security credentials and configure the cli.
![image](https://user-images.githubusercontent.com/21667569/234243961-e9e050fc-776a-48f4-a8a0-0636e65d168f.png)

```
ubuntu@rroberts-T14A:~/WSL$ aws configure
AWS Access Key ID [None]: #####
AWS Secret Access Key [None]: #####
Default region name [None]: us-east1
Default output format [None]: 
```

Create Key 
```
aws ec2 create-key-pair --key-name rr-key-2023-2 --query 'KeyMaterial' --output text  > ~/.ssh/rr-key-2023-2.pem
```


### Terraform install

This is very straightforward: https://developer.hashicorp.com/terraform/downloads

## Single Node Cluster VM deployment

The Terraform manifests below deploys a Single-Node in AWS.

![image](https://user-images.githubusercontent.com/21667569/234654647-c302bb38-d98c-4f12-9f4d-2c9c1a8d00f7.png)

### Use AMI with Pre-installed OAI


- Clone this repo and go to the "oai-testings/single-node/" folder
```
git clone https://github.com/robric/oai-testings.git
cd oai-testings/single-node/
```
- Edit variables (region, credentials, private key, ami) in variables.tf file:
```
ubuntu@rroberts-T14A:~/WSL/OAI/oai-testings/single-node$ cat variables.tf 
#
# provider variables: region, names, OAI ami
#
variable "provider_region" {
 description = "Provider region"
 default = "us-east-1"
}
variable "server_instance_type" {
  description = "Server instance type"
  default = "t2.xlarge"
}
variable "server_tag_name" {
  description = "Server tag name"
  default = "rr-oai-test-instance"
}
variable "ami_id" {
  description = "OAI-ready-to-use Ubuntu jammy image with minikube, OAI images, helm and charts"
  default = "ami-0fb0fac0077bfb65c"
}
#
# Credentials for ssh access to EC2 instances
#
variable "private_key_file" {
  description = "Private key file location for ssh access"
  default = "~/.ssh/rr-key-2023-2.pem"
}
variable "key_name" {
  description = "EC2 Key name"
  default = "rr-key-2023-2"
}

#
# Script for OAI deployment
#

variable "oai_deployment_file" {
  description = "Local script to deploy OAI"
  default = "deploy-single-node.sh"
}
 ```
- Launch terraform for single node cluster. The script for the deployment of OAI (i.e. "deploy-single-node.sh") is automatically copied and executed in the EC2 instance. 
```
terraform init
terraform validate
terraform plan
terraform apply
```

###



# OAI deployment in WSL2 (CRASHES)

Note on the deployment of OAI on windows WSL. Since we're in an environemnt with with limited resources and networking capabilities, the deployment is kept very simple. 

## Deployment Minikube + Basic Core + gNB RF simulated

### Preparation

Install the following:
- Kubernetees (minikube here) => https://minikube.sigs.k8s.io/docs/start/
- Helm =>  https://helm.sh/docs/intro/install/
- Helm Spray => command "helm plugin install https://github.com/ThalesGroup/helm-spray"

Clone the git repo with helm charts (here master is used -> Need to check whether there are recommended branches)
```
git clone https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed
```



### Deploy 

Create a dedicated k8s namespace and deploy charts with helm. 

```
kubectl create ns oai-tutorial
cd charts/oai-5g-core/oai-5g-basic
helm dependency update
helm spray --namespace oai-tutorial .
```

The deployment fails, but this is probably because my VM is too slow. I had to wait/try several times for readyness of the pods. 
```console
ubuntu@rroberts-T14A:~/WSL/OAI/oai-cn5g-fed/charts/oai-5g-core/oai-5g-basic$ helm spray --namespace oai-tutorial .
[spray] processing chart from local file or directory "."...
[spray] deploying solution chart "." in namespace "oai-tutorial"
[spray] processing sub-charts of weight 0
[spray]   > upgrading release "mysql": deploying first revision (appVersion 8.0.31)...
[spray]     o release: "mysql" upgraded
[spray]   > upgrading release "oai-nrf": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-nrf" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 1
[spray]   > upgrading release "oai-udr": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-udr" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 2
[spray]   > upgrading release "oai-udm": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-udm" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 3
[spray]   > upgrading release "oai-ausf": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-ausf" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 4
[spray]   > upgrading release "oai-amf": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-amf" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 5
[spray]   > upgrading release "oai-spgwu-tiny": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-spgwu-tiny" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 6
[spray]   > upgrading release "oai-smf": deploying first revision (appVersion v1.5.0)...
[spray]     o release: "oai-smf" upgraded
[spray]   > waiting for liveness and readiness...
[spray] upgrade of solution chart "." completed in 2m1s
ubuntu@rroberts-T14A:~/WSL/OAI/oai-testings$ kubectl get pods -n oai-tutorial
NAME                              READY   STATUS    RESTARTS   AGE
mysql-795c8b8d7f-h8t9z            1/1     Running   0          3m6s
oai-amf-6ccd8654d8-6n7vf          2/2     Running   0          107s
oai-ausf-87b7dfbd9-nh75j          2/2     Running   0          118s
oai-nrf-77677847d6-pknb4          2/2     Running   0          3m6s
oai-smf-6cb77d9844-7cmb9          2/2     Running   0          80s
oai-spgwu-tiny-78c7b4fc46-g7jn5   2/2     Running   0          91s
oai-udm-96b854bf9-4ptqs           2/2     Running   0          2m9s
oai-udr-5c9cb57dd7-zfb87          2/2     Running   0          2m19s
```

### gNB 

The gNB crashes. 

```
ubuntu@rroberts-T14A:~$ kubectl get pods -n oai-tutorial
*NAME                              READY   STATUS    RESTARTS        AGE
mysql-795c8b8d7f-h8t9z            1/1     Running   1 (93s ago)     23h
oai-amf-6ccd8654d8-6n7vf          1/2     Running   3 (32s ago)     23h
oai-ausf-87b7dfbd9-nh75j          2/2     Running   3 (32s ago)     23h
oai-gnb-67f978678d-cz7gf          1/2     Error     106 (41s ago)   23h
oai-nr-ue-647bd959f7-bt6t7        1/2     Error     108 (39s ago)   23h
oai-nrf-77677847d6-pknb4          2/2     Running   2 (93s ago)     23h
oai-smf-6cb77d9844-7cmb9          1/2     Running   3 (33s ago)     23h
oai-spgwu-tiny-78c7b4fc46-g7jn5   2/2     Running   3 (38s ago)     23h
oai-udm-96b854bf9-4ptqs           2/2     Running   3 (33s ago)     23h
oai-udr-5c9cb57dd7-zfb87          2/2     Running   2 (93s ago)     23h
ubuntu@rroberts-T14A:~$ 
```

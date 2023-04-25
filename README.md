# OAI deployment in WSL2

Note on the deployment of OAI on windows WSL. Since we're in an environemnt with with limited resources and networking capabilities, the deployment is kept very simple. 

Most information is derived from https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_HC.md and links.

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

### Tuning

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

# Testing with AWS from scratch

## [If not yet done] Install aws-cli -from scratch-

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

## Deploy EC2 Instance

Create Key 

```
aws ec2 create-key-pair --key-name rr-key-2023 --query 'KeyMaterial' --output text  > rr-key-2023.pem
```

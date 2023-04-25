# OAI deployment in WSL2

Note on the deployment of OAI on windows WSL. Since we're in an environemnt with with limited resources and networking capabilities, the deployment is kept very simple. 

Most information is derived from https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_HC.md and links.

# Deployment

## Preparation

You need to install
- Kubernetees
- Helm 
- Helm Spray. 

No need to explain how to install these :-), but here some shortcuts: 
- Ubuntu install for helm: https://helm.sh/docs/intro/install/
- Run the following command "helm plugin install https://github.com/ThalesGroup/helm-spray"

## Deployment 

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
'''console
ubuntu@rroberts-T14A:~/WSL/OAI/oai-cn5g-fed/charts/oai-5g-core/oai-5g-basic$ helm spray --namespace oai-tutorial .
[spray] processing chart from local file or directory "."...
[spray] deploying solution chart "." in namespace "oai-tutorial"
[spray] processing sub-charts of weight 0
[spray]   > upgrading release "mysql": going from revision 1 (status deployed) to 2 (appVersion 8.0.31)...
[spray]     o release: "mysql" upgraded
[spray]   > upgrading release "oai-nrf": going from revision 1 (status deployed) to 2 (appVersion v1.5.0)...
[spray]     o release: "oai-nrf" upgraded
[spray]   > waiting for liveness and readiness...
[spray] processing sub-charts of weight 1
[spray]   > upgrading release "oai-udr": going from revision 1 (status deployed) to 2 (appVersion v1.5.0)...
[spray]     o release: "oai-udr" upgraded
[spray]   > waiting for liveness and readiness...
Error: timed out waiting for liveness and readiness
Error: plugin "spray" exited with error
'''

# Testing with AWS from scratch

## [If not yet done] Install aws-cli -from scratch-

This is documented here:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

On Linux:

'''
sudo apt-get install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
'''

Create an Access Key in security credentials and configure the cli.
![image](https://user-images.githubusercontent.com/21667569/234243961-e9e050fc-776a-48f4-a8a0-0636e65d168f.png)

'''
ubuntu@rroberts-T14A:~/WSL$ aws configure
AWS Access Key ID [None]: #####
AWS Secret Access Key [None]: #####
Default region name [None]: us-east1
Default output format [None]: 
'''

## Deploy EC2 Instance

Create Key 

'''
aws ec2 create-key-pair --key-name rr-key-2023 --query 'KeyMaterial' --output text  > rr-key-2023.pem
'''

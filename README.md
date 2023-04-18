# OAI deployment in WSL2 

Note on the deployment of OAI on windows WSL. Since we're in an environemnt with with limited resources and networking capabilities, the deployment is kept very simple.

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

### ???later

Create a dediated k8s ns
```
kubectl create ns oai-tutorial
```




#!/bin/bash

# Function for handling the "core" CNF
handle_core() {
    echo "Handling core CNF..."
    #  Installation for "core" CNF
    kubectl create ns oai
    cd ~/oai-cn5g-fed/charts/oai-5g-core/oai-5g-basic
    helm dependency update
    helm spray --namespace oai .
}

# Function for handling the "gnb" CNF
handle_gnb() {
    echo "Handling gnb CNF..."
    # Installation for "gnb" CNF
    kubectl create ns oai
    cd ~/oai-cn5g-fed/charts/oai-5g-ran
    helm install gnb oai-gnb --namespace oai
}

# Function for handling the "cuup" CNF
handle_cuup() {
    echo "Handling cuup CNF..."
    # Installation for "cuup" CNF
    kubectl create ns oai
    cd ~/oai-cn5g-fed/charts/oai-5g-ran
}

# Function for handling the "cucp" CNF
handle_cucp() {
    echo "Handling cucp CNF..."
    #  Installation for "cucp" CNF
    kubectl create ns oai
    cd ~/oai-cn5g-fed/charts/oai-5g-ran
    helm install cucp oai-gnb-cu-cp/ --namespace oai
}

# Function for handling the "du+ue" CNF
handle_du_ue() {
    echo "Handling du+ue CNF..."
    #  Installation for "du+ue" CNF
    kubectl create ns oai
    cd ~/oai-cn5g-fed/charts/oai-5g-ran
    helm install nrue oai-nr-ue/ --namespace oai
}
init_variables(){
    export AMF_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].metadata.name}")
    export SMF_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-smf" -o jsonpath="{.items[0].metadata.name}")
    export SPGWU_TINY_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-spgwu-tiny" -o jsonpath="{.items[0].metadata.name}")
    export AMF_eth0_POD_IP=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].status.podIP}")
    export GNB_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[0].metadata.name}")
    export GNB_eth0_IP=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=gnb" -o jsonpath="{.items[*].status.podIP}")
    export NR_UE_POD_NAME=$(kubectl get pods --namespace oai -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=nrue" -o jsonpath="{.items[0].metadata.name}")
}
handle_test_ue() {
    echo "Checking that UE is properly connected..."
    #  Test if UE got an IP address
    output=$(kubectl exec -it -n oai -c nr-ue $NR_UE_POD_NAME -- ifconfig oaitun_ue1 | grep -E '(^|\s)inet($|\s)' | awk '{print $2}')    
    # Check if the output variable is not empty
    if [[ -n "$output" ]]; then
        echo "The UE is UP with IP address: $output !"
    else
        echo "The UE is DOWN"
    fi
}
handle_test_gnb() {
    echo "Checking that gNB is attached to the AMF..."
    #  Checking if gNB is attached to the AMF
    output=$(kubectl logs -c amf $AMF_POD_NAME -n oai  | grep 'Sending NG_SETUP_RESPONSE Ok')    
    # Check if the output variable is not empty
    if [[ -n "$output" ]]; then
        echo "The gNB is attached: $output !"
    else
        echo "The gNB is not attached is DOWN"
    fi
}
handle_test_core() {
    echo "Checking that gNB is initialized"
    #  placeholder
}
# Main script logic
main() {
    # Parse command-line options
    while [ $# -gt 0 ]; do
        case "$1" in
            --deploy)
                cnf="$2"
                shift 2
                ;;
            --test)
                test="$2"
                shift 2
                ;;
            *)
                echo "Invalid option: $1"
                exit 1
                ;;
        esac
    done

    # Check if CNF is specified
    if [ -n "$cnf" ]; then
        # Call the appropriate function based on the specified CNF
        case "$cnf" in
            core)
                handle_core
                ;;
            gnb)
                handle_gnb
                ;;
            cuup)
                handle_cuup
                ;;
            cucp)
                handle_cucp
                ;;
            du+ue)
                handle_du_ue
                ;;
            *)
                echo "Invalid CNF: $cnf"
                echo "Allowed values for <cnf>: core, gnb, cuup, cucp, du+ue"
                exit 1
                ;;
        esac
    elif [ -n "$test" ]; then
        # Call the appropriate function based on the specified test
        case "$test" in
            ue)
                init_variables
                handle_test_ue
                ;;
            gnb)
                init_variables
                handle_test_gnb
                ;;
            core)
                handle_test_core
                ;;
            *)
                echo "Invalid test: $test"
                echo "Allowed values for <test>: ue, gnb, core"
                exit 1
                ;;
        esac
    else
        echo "At least one of --deploy or --test is required."
        exit 1
    fi
}

# Call the main function
main "$@"
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FOLDER_ABOVE="$(dirname "$DIR")"
FOLDER_ABOVE_ABOVE="$(dirname "$FOLDER_ABOVE")"

echo ${DIR}

replacedBy_DOMAIN_A=$1
replacedBy_DOMAIN_B=$3
replacedBy_IP_A=$2
replacedBy_IP_B=$4

echo "Domain from participant a: $replacedBy_DOMAIN_A"
echo "Domain from participant b: $replacedBy_DOMAIN_B"
echo "IP from participant a: $replacedBy_IP_A"
echo "IP from participant b: $replacedBy_IP_B"


echo "Configuring SPIRE setup"
#copy template file that will be modified
cp ${DIR}/template/participant-a/agent-configmap.yaml ${DIR}/participant-a/agent-configmap.yaml
cp ${DIR}/template/participant-a/server-configmap.yaml ${DIR}/participant-a/server-configmap.yaml
cp ${DIR}/template/participant-b/agent-configmap.yaml ${DIR}/participant-b/agent-configmap.yaml
cp ${DIR}/template/participant-b/server-configmap.yaml ${DIR}/participant-b/server-configmap.yaml

#replace domains in file
sed -i -- "s/AUTOREPLACE_DOMAIN_A/$replacedBy_DOMAIN_A/g" ${DIR}/participant-a/*
sed -i -- "s/AUTOREPLACE_DOMAIN_A/$replacedBy_DOMAIN_A/g" ${DIR}/participant-b/*
sed -i -- "s/AUTOREPLACE_DOMAIN_B/$replacedBy_DOMAIN_B/g" ${DIR}/participant-a/*
sed -i -- "s/AUTOREPLACE_DOMAIN_B/$replacedBy_DOMAIN_B/g" ${DIR}/participant-b/*

#replace IPs in file
sed -i -- "s/AUTOREPLACE_IP_A/$replacedBy_IP_A/g" ${DIR}/participant-a/*
sed -i -- "s/AUTOREPLACE_IP_A/$replacedBy_IP_A/g" ${DIR}/participant-b/*
sed -i -- "s/AUTOREPLACE_IP_B/$replacedBy_IP_B/g" ${DIR}/participant-a/*
sed -i -- "s/AUTOREPLACE_IP_B/$replacedBy_IP_B/g" ${DIR}/participant-b/*

#remove existing SPIRE
echo "Removing existing SPIRE namespace"
kubectl --kubeconfig=${DIR}/kubeconfig-part-a delete ns spire
kubectl --kubeconfig=${DIR}/kubeconfig-part-b delete ns spire

#setup SPIRE on each machine inside cluster
echo "Setting up SPIRE"
kubectl --kubeconfig=${DIR}/kubeconfig-part-a apply -k ${DIR}/participant-a/
kubectl --kubeconfig=${DIR}/kubeconfig-part-b apply -k ${DIR}/participant-b/

#generate trust bundles
echo "Extracting trust bundles"
kubectl --kubeconfig=${DIR}/kubeconfig-part-a exec -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle show -format spiffe > ${DIR}/part-a.bundle
kubectl --kubeconfig=${DIR}/kubeconfig-part-b exec -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle show -format spiffe > ${DIR}/part-b.bundle

#set trust bundle
echo "Setting trust bundles"
kubectl --kubeconfig=${DIR}/kubeconfig-part-a exec -i -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://${replacedBy_DOMAIN_B} < ${DIR}/part-b.bundle
kubectl --kubeconfig=${DIR}/kubeconfig-part-b exec -i -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://${replacedBy_DOMAIN_A} < ${DIR}/part-a.bundle

#check if bundle was set properly
echo "Checking bundle for participant-a"
kubectl --kubeconfig=${DIR}/kubeconfig-part-a logs -n spire spire-server-0 | grep '"Bundle refreshed"\|"Bundle set successfully"'
echo "Checking bundle for participant-b"
kubectl --kubeconfig=${DIR}/kubeconfig-part-b logs -n spire spire-server-0 | grep '"Bundle refreshed"\|"Bundle set successfully"'




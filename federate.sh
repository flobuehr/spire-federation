#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ${DIR}

DOMAIN_A=$1
BUNDLE=$2

echo "Domain from participant a: $DOMAIN_A"
#set trust bundle
echo "Setting trust bundles"
kubectl exec -i -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://${DOMAIN_A} < ${BUNDLE}
#check if bundle was set properly
echo "Checking bundle set"
kubectl logs -n spire spire-server-0 | grep '"Bundle refreshed"\|"Bundle set successfully"'
echo "NOTE: SPIFFE IDs for workloads must be registered with the SPIRE server!"


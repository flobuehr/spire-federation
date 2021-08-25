#! /usr/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ${DIR}

DOMAIN_B=$1
KUBECONFIG_A=$2

if [[ -f "$KUBECONFIG_A" ]]; then
	echo "Domain to be defederated: $DOMAIN_B"
	#delete trust bundle
	echo "Deleting trust bundles"
	kubectl --kubeconfig=${KUBECONFIG_A} exec -i -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle delete -mode delete -id spiffe://${DOMAIN_B}
else
	echo "Using default kubeconfig"
	echo "Domain to be defederated: $DOMAIN_B"
	#delete trust bundle
        echo "Deleting trust bundles"
	kubectl exec -i -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle delete -mode delete -id spiffe://${DOMAIN_B}
fi


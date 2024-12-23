# Restart minikube from a stop or crash - configure the settings to your requirements and hardware
minikube start --cpus 4 --memory 12288 --vm-driver kvm2 --disk-size 100g --insecure-registry="192.168.39.0/24"

# Once it is restarted
minikube addons enable dashboard

# Start dashboard
minikube dashboard

# Open a new terminal window.
# Make sure the encrypted etcd is working and display the secret in plaintext. The 
# output should be 'supersecret'.
echo `kubectl get secrets -n default a-secret -o jsonpath='{.data.key1}'` | base64 --decode


# Now we need to unseal the vault pods using the prior generated unseal key(s)
WORKDIR=/media/tim/ExtraDrive1/Projects/learn-02-advanced-ingress

#Display the unseal key
jq -r ".unseal_keys_b64[]" ${WORKDIR}/crypto/cluster-keys.json

#Create env variable for the key
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ${WORKDIR}/crypto/cluster-keys.json) 
 
#Unseal vault-0
echo "Unseal vault-0"
kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY 

#Unseal vault-1
kubectl exec -it -n vault vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY

#unseal vault-2
kubectl exec -it -n vault vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY

#Display root token found in cluster-keys.json
jq -r ".root_token" ${WORKDIR}/crypto/cluster-keys.json

export CLUSTER_ROOT_TOKEN=$(cat ${WORKDIR}/crypto/cluster-keys.json | jq -r ".root_token")

#Start a shell into vault-0 and login 
kubectl exec -n vault vault-0 -- vault login $CLUSTER_ROOT_TOKEN

#List the raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers

#Review HA status
kubectl exec -n vault vault-0 -- vault status

# Note - If you want to use the vault UI or curl then first go to a different terminal
# and set port forward
kubectl -n vault port-forward service/vault 8200:8200

### Restart is completed

# These steps incorporate the steps necessary to set up Vault as a Root and Intermediate
# CA, and finally generate a Certificate
#
# https://developer.hashicorp.com/vault/tutorials/pki/pki-engine
#
# There are 2 versions within this document. The first uses the Vault UI. The second 
# uses kubectl and vault cli commands. 
#
# ********** Note - All the steps in the first option using kubectl and vault cli work
# except the final step generating Certificates. However
# the steps within the UI do successfully work.
#
# Also if the UI is used to generate the Root and Intermediate Certs and Roles then
# the final step of generating Certificates work with both the kubectl / vault cli as
# well as curl.

cat ${WORKDIR}/policy/adminPolicy.hcl | kubectl exec -i -n vault vault-0 -- vault policy write admin -

#export VAULT_ADDR=https://vault-0.vault-internal:8200

kubectl exec -it -n vault vault-0 -- /bin/sh

#List policies
vault policy list

#Read admin policy
vault policy read admin

#exit Vault-0 shell
exit 

#Create an admin token
ADMIN_TOKEN=$(kubectl exec -it -n vault vault-0 -- vault token create -format=json -policy="admin" | jq -r ".auth.client_token")

#print out token
echo $ADMIN_TOKEN

#Retrieve token capabilities
kubectl exec -it -n vault vault-0 -- vault token capabilities $ADMIN_TOKEN sys/auth/approle

# Below is the vault ui url for logging into vault. Using the UI is the only option I
# found that would successfully complete the necessary tasks. Within the kubectl 
# command steps below I have indicated where I started receiving errors. All of the 
# commands are successful, except when trying to generate a new certificate at the final 
# step.
#
# Also the browser is going to complain about the self signed cert for the UI. Just
# accept.
#
# https://127.0.0.1:8200/ui
#
# If using the UI from this point on then login with the ADMIN_TOKEN above which has
# been displayed in the terminal via the echo command. 
#
# *** Note if login fails due to authentication error and you have logged into Vault UI
# before, follow the instructtions below to remove the old token. 
# receive an authentication error when entering
# If so then go to the Person icon and select Revoke token, the select Logout. This will
# give you a screen to enter the new token.
# 
# Step 1. Generate Root CA
# At the Dashboard
#    Select Details next to the Secrets engines
#    Select enable new engine
#    Select PKI Certificates
#    Keep Path as 'pki'
#    Set Max Lease TTL to 87600 hours
#    Submit Enable engine
#
#    On the pki Overview Tab it will complain that the PKI is not configured.
#    Select Configure PKI
#    Select Generate Root
#    On Root parameters - 
#      Type - select internal
#      Common name - example.com
#      Issuer name - root-2025
#      Not valid after - TTL 87600 hours
#      Within the Issuer URLs
#        Issuing certificates    - https://localhost:8200/v1/pki/ca
#        CRL distribution points - https://localhost:8200/v1/pki/crl
#        OCSP Servers            - https://localhost:8200/v1/ocsp    
#    Select Done
#
#    The View Root Certificate Screen appears. Next to the Certificate Pem Format
#      Select the Copy icon to copy the cert to the clipboard.
#      Save the copied cert as root_2025_ca.crt ( In $WORKDIR/crypto is a good place )
#
#    Return to the Dashboard screen
#
#    Add a Role for the root CA - Select pki -> Roles (The Tab) -> Create Role
#      Role Name - 2025-servers
#      Select Create
# 
#    Note you can verify and review the cert information with 
#    openssl x509 -in ${WORKDIR}/crypto/root_2024_ca.crt -text 
#  
# Step 2. Generate Intermediate CA
#    Select Secrets Engines on left and then Enable new engine
#    Select PKI Certificates
#      Path - pki_int
#      Max lease TTL - 43800 hours
#      Select Enable Engine 
#    The pki_int Overview screen will complain that the pki is not configured.    
#    Select Configure PKI
#    Select Generate Intermediate CSR
#      Type - internal
#      Common Name - example.com Intermediate Authority
#      Select Generate
#    On View Generated CSR 
#      Select the copy icon next to the CSR Pem and copy to clipboard.
#      Save the pem file as pki_intermediate.csr ($WORKDIR/csr a good place)
#
#    Now we need to sign the CSR with the Root CA.
#    Return to Dashboard - select pki Secrets engine -> Select Issuers tab
#    Select root-2025 issuer
#    Select Sign Intermediate tab
#      Paste Pem CSR into CSR field
#      Common name - example.com
#      Format      - pem_bundle
#      Select Save to sign
#
#    Copy Certificate via copy icon. Save to intermediate_cert.pem
#    Copy and save Issuing CA and CA Chain
#
#    Go to Dashboard -> select pki_int from Secrets engines
#    Select Configure PKI
#    Select Import a CA
#    PEM Bundle - Browse to and select the intermediate_cert.pem file you saved.
#    Select Import Issuer
#    Select Done
#
# Step 3. Create a Role
#    Either select the Issuers Tab from the pki_int secrets and note the issuer marked as
#       intermediate (or)
#    Using a terminal obtain the issuer id:
#      kubectl exec -it -n vault vault-0 -- vault read -field=default pki_int/config/issuers
#    Copy the id output
#  
#    From Dashboard -> pki_int -> Roles (View roles) -> Create Role
#    On Create a PKI Role 
#     Role name - example-dot-com
#     Toggle off the Use default Issuer
#       Select the issuer with the id output in the terminal step above
#     Under Not valid after enter TTL - 43800 hours
#     Expand Domain Handling
#       Turn on Allow subdomains
#       In Allowed domains enter - example.com
#       Select Create
#
# Step 4. Request Certificates
#    From Dashboard -> select pki_int -> Roles (View Roles) -> example-dot-com
#    Select the Generate certificate tab
#       Common name - test.example.com
#       Under Not Valid after - set TTL 24 hours
#       Select Generate

################################################################################
# Request Certificates from Intermediate CA
kubectl exec -it -n vault vault-0 -- vault write pki_int/issue/example-dot-com common_name="test2.example.com" ttl="24h"     

# This curl command is an alternative to the above. If using it remember the 
# string substitution.
curl --cacert $WORKDIR/crypto/vault.ca \
     --header "X-Vault-Token: ${ADMIN_TOKEN}" \
     --request POST \
     --data '{"common_name": "test3.example.com", "ttl": "24h"}' \
     https://127.0.0.1:8200/v1/pki_int/issue/example-dot-com | jq
     
# This Step 4. is now complete.     


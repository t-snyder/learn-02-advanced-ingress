#!/bin/bash

# This learning prototype was developed and tested using the following. If you are using
# a different OS such as windows or possibly a different flavor of Linux you may have to
# modify some of the scripts below and in other Steps.
#   a) Ubuntu             - 20.04.6 LTS
#   b) Minikube           - 1.34.0
#   c) Kubernetes         - 1.31.0
#   d) Docker             - 27.2.0
#   d) Cert-manager       - 1.15.3
#   e) Ingress-nginx      - 1.11.2
#   e) Hashicorp Vault    - 1,17.3
#   f) OpenSSL            - 3.4.0
#
# Laptop Machine configuration:
#     - Processor - Intel® Core™ i7-7700K CPU @ 4.20GHz × 8 
#       Memory    - 64 GB

# Open terminal 1
# Delete prior minikube
minikube delete

# Start minikube - configure the settings to your requirements and hardware
minikube start --cpus 4 --memory 12288 --vm-driver kvm2 --disk-size 100g

# Addons
minikube addons enable dashboard
minikube addons enable ingress

# Start dashboard
minikube dashboard

# Start a 2nd terminal to proceed

# The minikube setup is completed. We can now continue with the steps in setting up the 
# Hashicorp Vault TLS- Step-2-deployVaultTLS.sh

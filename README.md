# Nightscout installation
Heroku discontinue(d) their free plan. As alternative there is Oracle free tier. Let's use it to setup nice and fast NS instance. Guide requires just time and patience. So, brew coffee and let's start.

# Requirements
Setup Oracle account. This is very basic stuff. They will ask you for a credit card in order to verify. Give it. Latter you will be able to delete it. After seting up account, actions you need to take:


1. Create "Compute instance" `(Ampere type, OS: Ubuntu 22.04, 3 CPU, 8 GB RAM, leave disk default)`;
2. After instance is online, edit "Default Security List" and create 1 Ingress rule:
```
    Stateless: Checked
    Source Type: CIDR
    Source CIDR: 0.0.0.0/0
    IP Protocol: TCP
    Source port range: (leave-blank)
    Destination Port Range: 80
    Description: Allow HTTP connections
 ```   
Without this step you will not be able to access instance from outside!

# Installation
Login to the Oracle instance and execute (as a root):

`wget https://raw.githubusercontent.com/ponasromas/nightscout_installation/master/ns_install.sh -O - | sh`

Script will ask you few questions. Answer them and you are good to go.

# Note
Script tested on Oracle free tier Ubuntu 22.04 (not minimal!). It should work with other cloud/hosting providers as long as OS version is the same. If you feel, that guide is to obscure, please contact me at 0hwxgq7s@duck.com and I will help you. Take care.

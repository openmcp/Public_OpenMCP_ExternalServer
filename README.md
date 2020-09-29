# OpenMCP External Server

## Introduction of OpenMCP External Server

> External servers for NFS, DNS, and ETCD (Figuration Management) capabilities of the OpenMCP platform developed by KETI

## Requirement
> Ubuntu 16.04 


## How to Install
> NFS Installation
```
cd nfs_installer
./install.sh
```

> ETCD Installation
```
cd etcd_installer
./install.sh
```

> PowerDNS Installation
```
cd powerdns_installer

## PASSWORD Change
vi install.sh 
PW="changeme"

./install.sh
```

## Install Check

> Confirm NFS Installation
```
MY_ADDRESS=`ip route get 8.8.8.8 | head -1 | cut -d' ' -f8` # Personal IP Lookup
mkdir test_nfs # Create Test Directory
mount -t nfs $MY_ADDRESS:/home/nfs test_nfs # NFS Mount
df -h | grep test_nfs # Validate Mounted NFS Information
umount test_nfs # Unmount
rm -r test_nfs # Delete Test Directory
```
> Confirm ETCD Installation
```
# Check service operation status(Activate: If activate, success)
systemctl status etcd
systemctl status etcd_clone
```
> Confirm PowerDNS Installation
```
# Check if the service is up or down
systemctl status pdns
systemctl status pdns-recursor
systemctl status powerdns-admin

# URL Connection Confirmation
MY_ADDRESS=`ip route get 8.8.8.8 | head -1 | cut -d' ' -f8` # Personal IP Lookup
http://$MY_ADDRESS:8081 # PDNS Server
http://$MY_ADDRESS # PowerDNS Web UI(PwerDNS-admin)
```

## Governance

This project was supported by Institute of Information & communications Technology Planning & evaluation (IITP) grant funded by the Korea government (MSIT) (No.2019-0-00052, Development of Distributed and Collaborative Container Platform enabling Auto Scaling and Service Mobility)

#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file
scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
hostname1=$(ssh remoteadmin@server1-mgmt -- hostname)
ip1=$(ssh remoteadmin@server1-mgmt -- hostname -I | awk '{print $1}')
entryname1=$(ssh remoteadmin@server1-mgmt -- grep "192.168.16.4" /etc/hosts| awk '{print $2}' )
echo "hostname=$hostname1"
echo "host ip=$ip1"
echo "entryname=$entryname1"
if [ "$hostname1"="loghost" ] && [ "$ip1"="192.168.16.3" ] && [ "$entryname1"="webhost" ]; then
    echo "Right" 
else
    echo "Wrong"
fi

scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3
hostname1=$(ssh remoteadmin@server2-mgmt -- hostname)
ip1=$(ssh remoteadmin@server2-mgmt -- hostname -I | awk '{print $1}')
entryname1=$(ssh remoteadmin@server2-mgmt -- grep "192.168.16.3" /etc/hosts| awk '{print $2}' )
echo "hostname=$hostname1"
echo "host ip=$ip1"
echo "entryname=$entryname1"
if [ "$hostname1" = "webhost" ] && [ "$ip1" = "192.168.16.4" ] && [ "$entryname1" = "loghost" ]; then
    echo "Right"
else
    echo "Wrong"
fi

./configure-host.sh -hostentry loghost 192.168.16.3
./configure-host.sh -hostentry webhost 192.168.16.4

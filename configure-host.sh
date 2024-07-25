#!/bin/bash


# Function to log messages if verbose mode is enabled
#
log_message() {
    logger -t configure-host.sh "$1"
    [ "$verbose" == true ] && echo "$1"
}

# Ignore TERM, HUP, and INT signals
trap '' TERM HUP INT

# Default values
verbose=false

# Parse command line arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -verbose)
	    echo "verbose branch"
            verbose=true
            ;;
        -name)
	    echo "name branch"
            shift
            desiredName=$1
            ;;
        -ip)
	    echo "ip branch"
            shift
            desiredIPAddress=$1
            ;;
        -hostentry)
	    echo "entry branch"
            shift
            hostName=$1
            shift
            hostIP=$1
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done



# Function to update /etc/hostname and /etc/hosts
update_host_files() {
    echo "Hostname function"
    local name=$1
    local ip=$2

    # Update /etc/hostname
    if [ -n "$name" ]; then
        currentName=$(cat /etc/hostname)
	echo "$currentName"
        if [ "$currentName" != "$name" ]; then
            echo "$name" > /etc/hostname
	    sed -i "s/ $currentName$/ $name/" /etc/hosts
	    sudo hostnamectl set-hostname "$name"
            log_message "Updated /etc/hostname to $name"
        fi
    fi
}

update_ip () {
     curr_ip=$(hostname -I | awk '{print $1}')	
     des_ip=$1
     echo "current IP=$curr_ip"
     echo "desired IP=$des_ip"    
 
     sed -i "s/$curr_ip/$des_ip/" /etc/hosts
     sed -i "s/$curr_ip/$des_ip/" /etc/netplan/10-lxc.yaml
     netplan apply
}

update_entry () {
    local hostname=$1
    local ipaddress=$2
    local updated=false
    local entry="${ipaddress} ${hostname}"
    
    # Check if the hostname and IP address are already in /etc/hosts
    if grep -q "${entry}" /etc/hosts; then
        [ "$VERBOSE" = true ] && echo "No changes needed: ${entry} is already in /etc/hosts"
    else
        # Backup /etc/hosts
        sudo cp /etc/hosts /etc/hosts.bak
        
        # Check if the hostname exists with a different IP
        if grep -q "${hostname}" /etc/hosts; then
            # Update the existing entry with the new IP address
            sed -i "/${hostname}/c\\${entry}" /etc/hosts
            updated=true
        else
            # Add a new entry
            echo "${entry}" >> /etc/hosts
            updated=true
        fi
        
        if [ "$updated" = true ]; then
            echo "Updated /etc/hosts with: ${entry}"
            logger "Updated /etc/hosts with: ${entry}"
            [ "$VERBOSE" = true ] && echo "Changes made to /etc/hosts: ${entry}"
        fi
    fi
}


# Apply the configurations
if [ -n "$desiredName" ]; then
    update_host_files "$desiredName" 
fi

if [ -n "$hostName" ] && [ -n "$hostIP" ]; then
    update_entry "$hostName" "$hostIP"
fi

# Reload netplan configuration if IP address was updated
if [ -n "$desiredIPAddress" ]; then
    update_ip "$desiredIPAddress"
    #netplan apply
    log_message "Applied netplan configuration"
fi


#!/bin/bash

# Web server
if [ "$1" == "webserver" ]
then
    echo "Configuring ifconfig"

    cp -f network-managers/webserver_vm.yaml /etc/netplan/01-network-manager-all.yaml

    echo "Configuring NGINX"

    sudo apt install nginx -y
    rm /etc/nginx/sites-available/default
    cp nginx-config/webserver_config /etc/nginx/sites-available/default
    sudo systemctl restart nginx

# Firewall
elif [ "$1" == "firewall" ]
then    

    sudo apt install iptables-persistent -y

    echo "Configuring netplan"

    cp -f network-managers/firewall_vm.yaml /etc/netplan/01-network-manager-all.yaml

    echo "Configuring iptable policies and rules"

    echo "Setting default policy: DROP all traffic"
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

    echo "Allowing http and https traffic"
    # Allow incoming from any ip/port 
    iptables -A INPUT -p tcp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    # Allow outgoing to 192.168.0.2 to 80/443
    iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT


    echo "Allowing icmp traffic"
    iptables -A INPUT -p icmp -j ACCEPT
    iptables -A OUTPUT -p icmp -j ACCEPT

    echo "Allowing loopback traffic"
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    #echo "Allowing internal network to access external network"
    #iptables -A FORWARD -i "ethTODO" -o "ethTODO" -j ACCEPT

    echo "Allowing tcp traffic between web server and database"
    iptables -A FORWARD -p tcp -s 192.168.0.2/24 -d 192.168.1.2/24 --dport 5432 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -p tcp -s 192.168.1.2/24 --sport 5432 -d 192.168.0.2/24 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

    echo "Allowing external traffic to enter the web server through the firewall without knowing its IP address"

    #Redirect requests to firewall:80/443 to web_server:80/443
    iptables -A PREROUTING -t nat -p tcp -d 192.168.56.101 --dport 80 -j DNAT --to 192.168.0.2:80 
    iptables -A PREROUTING -t nat -p tcp -d 192.168.56.101 --dport 443 -j DNAT --to 192.168.0.2:443
    iptables -A FORWARD -d 192.168.0.2 -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -A FORWARD -d 192.168.0.2 -p tcp -m tcp --dport 443 -j ACCEPT
    
    #Redirect requests from web_server:80/443 to firewall:80/443 and change the source IP
    iptables -A FORWARD -s 192.168.0.2 -p tcp -m tcp --sport 80 -j ACCEPT
    iptables -A FORWARD -s 192.168.0.2 -p tcp -m tcp --sport 443 -j ACCEPT
    iptables -A POSTROUTING -t nat -p tcp -s 192.168.0.2 --sport 80 -j MASQUERADE
    iptables -A POSTROUTING -t nat -p tcp -s 192.168.0.2 --sport 443 -j MASQUERADE

    # FOR IPv4
    sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
    # FOR IPv6
    sudo sh -c 'ip6tables-save > /etc/iptables/rules.v6'

# Database
elif [ "$1" == "database" ]
then
    echo "Configuring netplan"

    cp -f network-managers/database_vm.yaml /etc/netplan/01-network-manager-all.yaml

    echo "Installing PostgreSQL"

    sudo wget http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc
    sudo apt-key add ACCC4CF8.asc
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
    sudo apt -y update
    sudo apt -y install postgresql-14

    echo "Configuring postgres permissions for ssl"

    chown postgres:ssl-cert /etc/ssl/private/
    chown postgres:postgres /etc/ssl/private/webserver.key
    chown postgres:ssl-cert /etc/ssl/certs/
    chown postgres:postgres /etc/ssl/certs/webserver.crt

# Internal user
elif [ "$1" == "internaluser" ]
then
    echo "Configuring netplan"

    cp -f network-managers/internaluser_vm.yaml /etc/netplan/01-network-manager-all.yaml

# External service
elif [ "$1" == "externalservice" ]
then
    echo "Configuring netplan"

    cp -f network-managers/externalservice_vm.yaml /etc/netplan/01-network-manager-all.yaml

    echo "Configuring NGINX"

    sudo apt install nginx -y
    rm /etc/nginx/sites-available/default
    cp nginx-config/externalservice_config /etc/nginx/sites-available/default
    sudo systemctl restart nginx

else
    echo "Usage: $0 <webserver|firewall|database|internaluser|externalservice>"
    exit 1
fi

netplan try ; netplan apply
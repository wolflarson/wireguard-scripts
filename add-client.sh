#!/usr/bin/env bash

if [ $# -eq 0 ]
then
	echo "must pass a client name as an arg: add-client.sh new-client"
else
	echo "Creating client config for: $1"
	mkdir -p "clients/$1"
	wg genkey | tee clients/$1/$1.priv | wg pubkey > clients/$1/$1.pub
	key=$(cat clients/$1/$1.priv) 
	ip="192.168.8."$(( $(cat last-ip.txt | tr "." " " | awk '{print $4}') + 1))
	FQDN=$(hostname -f)
	SERVER_PUB_KEY=$(cat /etc/wireguard/server_public_key)
	cat wg0-client.example.conf | sed -e 's/:CLIENT_IP:/'"$ip"'/' | sed -e 's|:CLIENT_KEY:|'"$key"'|' | sed -e 's|:SERVER_PUB_KEY:|'"$SERVER_PUB_KEY"'|' | sed -e 's|:SERVER_ADDRESS:|'"$FQDN"'|' > clients/$1/wg0.conf
	echo "$ip" > last-ip.txt
	cp SETUP.txt clients/$1/SETUP.txt
	tar czvf clients/$1.tar.gz clients/$1
	echo "Created config!"
	echo "Adding peer"
	sudo wg set wg0 peer "$(cat clients/$1/$1.pub)" allowed-ips $ip/32
	echo "Adding peer to hosts file"
	echo "$ip $1" | sudo tee -a /etc/hosts
	sudo wg show
	if [[ "$(command -v qrencode)" = *"qrencode"* ]]; then
		qrencode -t ansiutf8 < clients/$1/wg0.conf
	fi
fi

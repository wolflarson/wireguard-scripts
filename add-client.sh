#!/usr/bin/env bash
# CIDR you used in your wg config without the last octet
CIDRPrefix="192.168.8."
wgPubKeyLocation="/etc/wireguard/public.key"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ $# -eq 0 ]
then
	echo "must pass a client name as an arg: add-client.sh new-client"
else
	echo "Creating client config for: $1"
	if [[ ! -f last-ip.txt ]]; then
		echo "1" > last-ip.txt
	fi

	if [[ -d "clients/$1" ]]; then
		echo "You already have a client with that name."
		exit
	else
		mkdir -p "clients/$1"
	fi
	wg genkey | tee "clients/$1/$1.priv" | wg pubkey > "clients/$1/$1.pub"
	key=$(cat "clients/$1/$1.priv")
	ip="$CIDRPrefix"$(( $(cat last-ip.txt | tr "." " " | awk '{print $4}') + 1))
	FQDN="$(curl ifconfig.me)"
	SERVER_PUB_KEY=$(cat "$wgPubKeyLocation")
	cat wg0-client.example.conf | sed -e 's/:CLIENT_IP:/'"$ip"'/' | sed -e 's|:CLIENT_KEY:|'"$key"'|' | sed -e 's|:SERVER_PUB_KEY:|'"$SERVER_PUB_KEY"'|' | sed -e 's|:SERVER_ADDRESS:|'"$FQDN"'|' > clients/$1/wg0.conf
	echo "$ip" > last-ip.txt
	cp SETUP.txt clients/$1/SETUP.txt
	tar czvf clients/$1.tar.gz clients/$1
	echo "Adding peer"
	wg set wg0 peer "$(cat clients/$1/$1.pub)" allowed-ips $ip/32
	echo "Adding peer to hosts file"
	echo "$ip $1" | tee -a /etc/hosts
	wg show
	if [[ "$(command -v qrencode)" = *"qrencode"* ]]; then
		qrencode -t ansiutf8 < clients/$1/wg0.conf
	fi
fi

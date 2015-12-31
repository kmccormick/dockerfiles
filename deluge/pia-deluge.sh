#!/bin/bash
# OpenVPN tunnel device
dev=tun0

# deluge's config directory
deluge_config=/config/deluge

# VPN Service Port Forward API URL
url=https://www.privateinternetaccess.com/vpninfo/port_forward_assignment

# Credentials for URL (username\npassword)
auth_file=/config/openvpn/pia.cred

# Unique client ID
client_id_file=/config/openvpn/pia_client_id

# OpenVPN config file short name
openvpn=pia

# Exit gracefully if we get TERM (docker stop)
trap 'echo got TERM; deluge-stop; exit' TERM

# Create the tun device node & tun0 device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
openvpn --mktun --dev $dev

# Start openvpn
openvpn --dev $dev --writepid /run/openvpn.${openvpn}.pid --daemon ovpn-${openvpn} --log /run/openvpn.${openvpn}.log --status /run/openvpn.${openvpn}.status --cd /config/openvpn --config /config/openvpn/${openvpn}.conf

# wait for tun device to have an ip
while ! (ip addr show dev $dev | grep "inet \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\} peer") ; do
	sleep 1
done
# wait for everything to finish coming up
sleep 2

echo
echo IP Address:
ip addr show dev $dev
echo
echo Routing Table:
ip route

# update-deluge: update deluge with new IP/port info
update-deluge() {
	pgrep deluged >/dev/null || exit
	deluge-console --config $deluge_config "config -s listen_interface $1"
	deluge-console --config $deluge_config "config -s listen_ports ($2,$2)"
}

# port-forward: get a forwarded port from the PIA server
port-forward() {

	lastport="$1"
	user=$(head -n1 $auth_file)
	pass=$(tail -n1 $auth_file)
	client_id=$(<$client_id_file)

	int_ip=$(ip addr show dev $dev | grep -w inet | awk '{print $2}')

	# Must send this request over the VPN!!
	response="$(curl -sSd "user=$user&pass=$pass&client_id=$client_id&local_ip=$int_ip" "$url")"

	# Clean up /etc/hosts
	#sed -i '/# pia-port-forward$/d' /etc/hosts

	logger -st port-forward "$response"
	# TODO: fail gracefully if we don't get a valid port
	port="$(echo "$response" | jq .port)"
	
	if [ "$port" != "$lastport" ] ; then
		logger -st port-forward "port change from $lastport to $port"
		update-deluge "$int_ip" "$port"
	fi
}

# keep-alive: kill PID 1 if we lose our forwarded port
keep-alive() {
	minutes=45
	port=$(port-forward)
	logger -st keep-alive "$0 started with port $port"
	while :; do
		sleep $(($minutes*60))
		new_port=$(port-forward)
		if ! [ "$port" = "$new_port" ] ; then
			logger -st keep-alive "$0 noticed change of port from $port to $new_port"
			port="$new_port"
			kill 1
		fi
	done
}

# deluge-stop: gracefully shutdown deluge
deluge-stop() {
	deluge-console --config $deluge_config halt
}

# watch-vpn: if openvpn goes away, shut down deluge
watch-vpn() {
	while :; do
		pgrep openvpn > /dev/null || deluge-stop
		ip route | grep -q 0.0.0.0/1 || deluge-stop
		sleep 5
	done
}

# watch-deluge: hang around until deluged is gone
watch-deluge() {
	while :; do
		sleep 5
		# check for it twice, make sure it wasn't a port-forward restart
		if ! pgrep deluged > /dev/null; then
			logger -st watch-deluge "Can't find deluged, checking again..."
			sleep 5
			pgrep deluged || exit
		fi
	done
}

# start deluged & deluge-web
start-stop-daemon --start --user deluge --group deluge --exec /usr/bin/deluged -- -L warning --config $deluge_config
start-stop-daemon --start --user deluge --group deluge --exec /usr/bin/deluge-web -- --fork --config ${deluge_config}_web

# keep things going
watch-vpn &
keep-alive &
watch-deluge &

# if deluge is gone, we're done
wait %watch-deluge

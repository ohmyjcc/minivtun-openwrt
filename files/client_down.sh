#!/bin/sh
# A modified script adapt for minivtun
# 
# Copyright (C) 2015 OpenWrt-dist
# Copyright (C) 2015 Jian Chang <aa65535@live.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

# This script will be executed when client is down.
# All key value pairs in ShadowVPN config file will be passed to this script
# as environment variables, except password.

PID=$(cat $pidfile 2>/dev/null)
loger() {
	echo "$(date '+%c') down.$1 minivtun[$PID] $2"
}

# Get uci setting
route_mode=$(uci get minivtun.@minivtun[-1].route_mode_save 2>/dev/null)

# mode 3 is "no change for route"
if [ "$route_mode" != 3 ]; then
	# Turn off NAT over VPN
	iptables -t nat -D POSTROUTING -o $intf -j MASQUERADE
	iptables -D FORWARD -i $intf -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -D FORWARD -o $intf -j ACCEPT
	loger notice "Turn off NAT over $intf"

	# Change routing table
	ip route del $server
	if [ "$route_mode" != 2 ]; then
		ip route del 0.0.0.0/1
		ip route del 128.0.0.0/1
		loger notice "Default route changed to original route"
	fi

	# Remove route rules
	if [ -f /tmp/minivtun_routes ]; then
		sed -e "s/^/route del /" /tmp/minivtun_routes | ip -batch -
		loger notice "Route rules have been removed"
	fi

	rm -rf /tmp/minivtun_routes
fi

loger info "Script $0 completed"

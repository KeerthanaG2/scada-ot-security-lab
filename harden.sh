#!/bin/sh
# Lab 2: only the HMI may reach Modbus (502). Run: docker exec plc sh /harden.sh  (copy in first, see README)
iptables -F INPUT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 502 -s 172.28.0.20 -j ACCEPT
iptables -A INPUT -p tcp --dport 502 -j DROP
iptables -L INPUT -n --line-numbers

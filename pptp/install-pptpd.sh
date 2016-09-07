#!/bin/bash



DNS1="223.6.6.6"
DNS2="119.29.29.29"

# clean
yum -y remove pptpd ppp

mv /etc/sysconfig/iptables{,.old}
systemctl restart iptables

rm -rf /etc/pptpd.conf
rm -rf /etc/ppp
rm -rf /dev/ppp

# install component
yum install make openssl gcc-c++ ppp iptables pptpd iptables-services

# /etc/ppp/chap-secrets
pass=`cat /dev/urandom | tr -dc "a-zA-Z0-9_+\~\!\@\#\$\%\^\&\*"| fold -w 16 |head -n1`
if [ "$1" != "" ]
  then pass=$1
fi
echo "liang pptpd ${pass} *" >> /etc/ppp/chap-secrets

# /etc/pptpd.conf
echo "localip 10.0.0.1-9" >> /etc/pptpd.conf
echo "remoteip 10.0.0.10-254" >> /etc/pptpd.conf

# /etc/ppp/options.pptpd
echo "ms-dns $DNS1" >> /etc/ppp/options.pptpd
echo "ms-dns $DNS2" >> /etc/ppp/options.pptpd

# /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p # 使内核转发生效

# iptables 配置
iptables -A FORWARD -p tcp --syn -s 10.0.0.0/24 -j TCPMSS --set-mss 1356
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

iptables -A INPUT -p tcp  --dport 1723 -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p gre -j ACCEPT
iptables -A OUTPUT  -p gre -j ACCEPT
/usr/libexec/iptables/iptables.init save

mknod /dev/ppp c 108 0

systemctl restart iptables
systemctl restart pptpd
# 开机自动启动
systemctl enable pptpd


echo ========== Install OK ==========
cat /etc/ppp/chap-secrets

#!/bin/bash

setenforce 0
systemctl stop firewalld

mkdir -p /tmp/gobgp
cd /tmp/gobgp && curl -s -L -O https://github.com/osrg/gobgp/releases/download/v3.30.0/gobgp_3.30.0_linux_amd64.tar.gz
tar xvzf gobgp_3.30.0_linux_amd64.tar.gz
mv gobgp /usr/bin/
mv gobgpd /usr/bin/

groupadd --system gobgpd
useradd --system -d /var/lib/gobgpd -s /bin/bash -g gobgpd gobgpd
mkdir -p /var/{lib,run,log}/gobgpd
chown -R gobgpd:gobgpd /var/{lib,run,log}/gobgpd
mkdir -p /etc/gobgpd
chown -R gobgpd:gobgpd /etc/gobgpd

DEFAULT_ROUTE_INTERFACE=$(cat /proc/net/route | cut -f1,2 | grep 00000000 | cut -f1)
DEFAULT_ROUTE_INTERFACE_IPV4=$(ip addr show dev $DEFAULT_ROUTE_INTERFACE | grep "inet " | sed "s/.*inet //" | cut -d"/" -f1)
BGP_AS=65005
BGP_PEER=10.0.0.60
cat << EOF > /etc/gobgpd/gobgpd.conf
[global.config]
  as = $BGP_AS
  router-id = "$DEFAULT_ROUTE_INTERFACE_IPV4"

[[neighbors]]
  [neighbors.config]
    neighbor-address = "$BGP_PEER"
    peer-as = $BGP_AS
EOF

cp gobgpd.service /usr/lib/systemd/system/

cat /etc/gobgpd/gobgpd.conf

systemctl enable gobgpd
systemctl start gobgpd
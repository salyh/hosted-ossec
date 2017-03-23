#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
yum -y install make gcc git flex bison libpcap-devel libdnet-devel.x86_64 zlib-devel libnghttp2-devel --enablerepo=epel

#https://www.upcloud.com/support/installing-snort-on-centos/

cd /
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz

tar xvfz daq-2.0.6.tar.gz
tar xvfz snort-2.9.9.0.tar.gz
                      
cd /daq-2.0.6
./configure && make && make install

cd /snort-2.9.9.0
./configure --enable-sourcefire && make && make install

cd /

ldconfig

ln -s /usr/local/bin/snort /usr/sbin/snort

groupadd snort
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

mkdir /etc/snort
mkdir /etc/snort/rules
mkdir /usr/local/lib/snort_dynamicrules
mkdir /var/log/snort

touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules /etc/snort/rules/local.rules
chmod -R 5775 /etc/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /usr/local/lib/snort_dynamicrules
chown -R snort:snort /etc/snort
chown -R snort:snort /var/log/snort
chown -R snort:snort /usr/local/lib/snort_dynamicrules

cp /snort*/etc/*.conf* /etc/snort
cp /snort*/etc/*.map /etc/snort


wget https://www.snort.org/rules/community -O /community.tar.gz
tar -xvf /community.tar.gz -C /
cp /community-rules/* /etc/snort/rules
sed -i 's/include \$RULE\_PATH/#include \$RULE\_PATH/' /etc/snort/snort.conf

#set conf /etc/snort/snort.conf


snort -T -c /etc/snort/snort.conf
#snort -i <interface> -u snort -g snort -c /etc/snort/snort.conf
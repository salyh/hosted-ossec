#!/bin/bash
#export API_KEY=abcdef
#curl --silent --location https://xxxx/ossec_agent/install | sudo bash -
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
#rpm or deb?
#install latest ossec agent deb/rpm
#apt-get --purge -y remove ossec-hids-agent


export OSSEC_MANAGER_IP="54.244.48.91"
#SNORT=1

check_cmd() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}


echo "client $OSSEC_MANAGER_IP" > /client


if check_cmd yum; then
    yum install -y inotify-tools aws-cli tcpdump --enablerepo=epel
    yum -y install make gcc git flex bison libpcap-devel pcre-devel libdnet-devel.x86_64 zlib-devel libnghttp2-devel --enablerepo=epel
    yum install -y https://ossec.wazuh.com/el/7/x86_64/ossec-hids-agent-2.8.3-4.el7.x86_64.rpm
else
	apt-get install -yqq expect
	URL='https://ossec.wazuh.com/repos/apt/ubuntu/pool/main/o/ossec-hids-agent/ossec-hids-agent_2.8.3-4xenial_amd64.deb'
	TMPFILE=`mktemp`
	wget "$URL" -qO $TMPFILE
	DEBIAN_FRONTEND=noninteractive dpkg -i --force-all $TMPFILE 
	rm -f $TMPFILE 
fi

cd /
wget http://download.redis.io/releases/redis-3.2.8.tar.gz
tar xvfz redis-3.2.8.tar.gz
cd redis-3.2.8
make distclean  
make
cd src
cp redis-server redis-cli /usr/local/bin

mv /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.orig

cat >/var/ossec/etc/ossec.conf <<EOL
<ossec_config>
  <client>
    <server-ip>RPLC_IP</server-ip>
    <config-profile>RPLC_PROFILE</config-profile>
  </client>
</ossec_config>
EOL

sed -i'' "s/RPLC_IP/$OSSEC_MANAGER_IP/" /var/ossec/etc/ossec.conf

/var/ossec/bin/agent-auth -m "$OSSEC_MANAGER_IP"
/var/ossec/bin/ossec-control restart

cd "$DIR"

if [ -z "$SNORT" ]; then
   sed -i'' 's/RPLC_PROFILE/default/' /var/ossec/etc/ossec.conf
   
   crontab -l > /tmp/rootcron.tmp 2>/dev/null

	if [[ $(cat /tmp/rootcron.tmp) != *"tcpdmps3"* ]]
	then
		   echo "* * * * * /usr/bin/flock -w 1000 /var/tcpdump.lock $DIR/tcpdmps3.sh" >> /tmp/rootcron.tmp
		   crontab /tmp/rootcron.tmp
	else
		   :
	fi

	rm -rf /tmp/rootcron.tmp
   
else
   sed -i'' 's/RPLC_PROFILE/snort/' /var/ossec/etc/ossec.conf
   echo "snort" > /snort_installed
   ./install_snort_server.sh
fi

#this needs to be secured via ssl certificates

#/var/ossec/bin/ossec-agentd -f -d

#get ip address

#register agent and get keys from server
# add server ip to agent
#curl -XPOST https://xxxx/ossec_agent/register/$API_KEY/$(HOSTNAME)
#//http://documentation.wazuh.com/en/latest/ossec_reference.html
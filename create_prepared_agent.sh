#!/bin/bash
#export API_KEY=abcdef
#curl --silent --location https://xxxx/ossec_agent/install | sudo bash -
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
#rpm or deb?
#install latest ossec agent deb/rpm
#apt-get --purge -y remove ossec-hids-agent

check_cmd() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}




create_cronjob() {

	#cat >/root/tcpdump_cronjob.sh <<'EOF'
	#!/usr/bin/env bash
	
	#PROCESS_NUM=$(ps -ef | grep "tcpdump" | grep -v "grep" | wc -l)
	
	
	
	#tcpdump -G 5 -C 1 -i any -K -nn -w /root/trace-%Y-%m-%d_%H:%M:%S.pcap &
	#EOF

	#chmod +x /root/tcpdump_cronjob.sh

	crontab -l > /tmp/rootcron.tmp 2>/dev/null

	if [[ $(cat /tmp/rootcron.tmp) != *"tcpdump_cronjob"* ]]
	then
		   echo "* * * * * /usr/bin/flock -w 0 /var/tcpdump.lock $DIR/tcpdmps3.sh" >> /tmp/rootcron.tmp
		   crontab /tmp/rootcron.tmp
	else
		   :
	fi

	rm -rf /tmp/rootcron.tmp

}

OSSEC_MANAGER_IP="54.191.154.184"
#SNORT=1


echo "client $OSSEC_MANAGER_IP" > /client

if check_cmd yum; then
    yum install -y inotify-tools aws-cli tcpdump --enablerepo=epel
    yum install -y https://ossec.wazuh.com/el/7/x86_64/ossec-hids-agent-2.8.3-4.el7.x86_64.rpm
else
	apt-get install -yqq expect
	URL='https://ossec.wazuh.com/repos/apt/ubuntu/pool/main/o/ossec-hids-agent/ossec-hids-agent_2.8.3-4xenial_amd64.deb'
	TMPFILE=`mktemp`
	wget "$URL" -qO $TMPFILE
	DEBIAN_FRONTEND=noninteractive dpkg -i --force-all $TMPFILE 
	rm -f $TMPFILE 
fi

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

if [ -z "$SNORT" ]; then
   sed -i'' 's/RPLC_PROFILE/default/' /var/ossec/etc/ossec.conf
   create_cronjob   
else
   sed -i'' 's/RPLC_PROFILE/snort/' /var/ossec/etc/ossec.conf
   echo "snort" > /snort_installed
   ./install_snort_server.sh
fi

#this needs to be secured via ssl certificates
/var/ossec/bin/agent-auth -m "$OSSEC_MANAGER_IP"
/var/ossec/bin/ossec-control restart
#/var/ossec/bin/ossec-agentd -f -d

#get ip address

#register agent and get keys from server
# add server ip to agent
#curl -XPOST https://xxxx/ossec_agent/register/$API_KEY/$(HOSTNAME)
#//http://documentation.wazuh.com/en/latest/ossec_reference.html
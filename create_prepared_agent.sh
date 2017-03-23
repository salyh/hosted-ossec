#!/bin/bash
#export API_KEY=abcdef
#curl --silent --location https://xxxx/ossec_agent/install | sudo bash -
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

OSSEC_MANAGER_IP="54.191.154.184"
#SNORT=1

if check_cmd yum; then
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
   
   #tcpdump -G 5 -C 1 -i any -K -nn -w trace-%Y-%m-%d_%H:%M:%S.pcap
   #aws s3api put-bucket-accelerate-configuration --bucket bucketname --accelerate-configuration Status=Enabled
   #aws s3 cp file.txt s3://ossecondkunde1/123 --region us-west-2
   
else
   sed -i'' 's/RPLC_PROFILE/snort/' /var/ossec/etc/ossec.conf
   
   ./install_snort_server.sh
   
   
fi

#this needs to be secured via ssl certificates
/var/ossec/bin/agent-auth -m "$OSSEC_MANAGER_IP"
/var/ossec/bin/ossec-control restart
#/var/ossec/bin/ossec-agentd -f -d




#tcpdump -s 0 port ftp or ssh -i eth0 -w mycap.pcap
#https://enterprise.cloudshark.org/blog/streaming-live-captures-to-cloudshark/



#send events

#An Amazon Simple Notification Service (Amazon SNS) topic – A web service that coordinates and manages the delivery or sending of messages to subscribing endpoints or clients.
#An Amazon Simple Queue Service (Amazon SQS) queue – Offers reliable and scalable hosted queues for storing messages as they travel between computer.
#A Lambda function – AWS Lambda is a compute service where you can upload your code and the service can run the code on your behalf using the AWS infrastructure. You package up and upload your custom code to AWS Lambda when you create a Lambda function

#get ip address

#register agent and get keys from server
# add server ip to agent
#curl -XPOST https://xxxx/ossec_agent/register/$API_KEY/$(HOSTNAME)
#//http://documentation.wazuh.com/en/latest/ossec_reference.html
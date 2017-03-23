#!/bin/bash
#udp 1514
#tcp 1515

#TODO:
# update_ruleset.py not working yet


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

ID="ccossec1"

echo "$ID" > /ID

ELASTIC_HOST="https://9afbe6de76d467ba76d3bacda75a6006.us-east-1.aws.found.io:9243"
ELASTIC_USER="elastic"
ELASTIC_PASSWD="zoERW3xdkDHEUXimrbdcMLGJ"

yum -y -q update
yum -y -q install make gcc git openssl-devel openssl
cd /
BRANCH="master" #stable
rm -rf ossec-wazuh
git clone -b $BRANCH https://github.com/wazuh/wazuh.git ossec-wazuh
cd ossec-wazuh
cat "$DIR/wazuh_server.conf" > etc/preloaded-vars.conf
./install.sh
echo $(openssl rand -base64 32) > /var/ossec/etc/authd.pass
openssl genrsa -out /var/ossec/etc/sslmanager.key 2048
openssl req -new -x509 -key /var/ossec/etc/sslmanager.key -out /var/ossec/etc/sslmanager.cert -days 365 -subj "/C=DE/ST=A/L=D/O=Network/OU=IT Department/CN=hostname.org"
/var/ossec/bin/ossec-control start
/var/ossec/bin/ossec-authd -p 1515 -a >/dev/null 2>&1 &
cd /
mkdir -p /var/ossec/ruleset
git clone https://github.com/wazuh/wazuh-ruleset
cd wazuh-ruleset
#./update_ruleset.py -rfd
cd /
curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs
git clone https://github.com/wazuh/wazuh-api
cd wazuh-api
./install_api.sh
/var/ossec/api/scripts/install_daemon.sh
service wazuh-api start
cat /var/ossec/api/configuration/config.js

cat >/var/ossec/etc/shared/agent.conf <<EOL
<agent_config>

    <!-- $ID -->

    <!-- only relevant for snort agent -->
    <localfile profile="snort">
       <location>/snort-full.log</location>
       <log_format>snort-full</log_format>
    </localfile>

    <localfile>
        <location>/var/log/kern.log</location>
        <log_format>syslog</log_format>
    </localfile>

    <localfile>
        <location>/var/log/auth.log</location>
        <log_format>syslog</log_format>
    </localfile>

    <localfile>
        <location>/var/log/noexists.log</location>
        <log_format>syslog</log_format>
    </localfile>
  
  <syscheck>
    <!-- Frequency that syscheck is executed -- default every 2 hours -->
    <frequency>7200</frequency>

    <!-- Directories to check  (perform all possible verifications) -->
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin</directories>

    <!-- Files/directories to ignore -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/httpd/logs</ignore>
  </syscheck>

  <rootcheck>
    <rootkit_files>/var/ossec/etc/shared/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>/var/ossec/etc/shared/rootkit_trojans.txt</rootkit_trojans>
    <system_audit>/var/ossec/etc/shared/system_audit_rcl.txt</system_audit>
  </rootcheck>
  
</agent_config>
EOL


chown root:ossec /var/ossec/etc/shared/agent.conf
/var/ossec/bin/ossec-control restart

yum install -y https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.2.2-x86_64.rpm

cat >/etc/filebeat/filebeat.yml <<EOL

filebeat.prospectors:

# Each - is a prospector. Most options can be set at the prospector level, so
# you can use different prospectors for various configurations.
# Below are the prospector specific configurations.

- input_type: log

  # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - "/var/ossec/logs/alerts/alerts.json"
    #- c:\programdata\elasticsearch\logs\*
    
  document_type: json
  json.message_key: log
  json.keys_under_root: true
  json.overwrite_keys: true  

  # Exclude lines. A list of regular expressions to match. It drops the lines that are
  # matching any regular expression from the list.
  #exclude_lines: ["^DBG"]

  # Include lines. A list of regular expressions to match. It exports the lines that are
  # matching any regular expression from the list.
  #include_lines: ["^ERR", "^WARN"]

  # Exclude files. A list of regular expressions to match. Filebeat drops the files that
  # are matching any regular expression from the list. By default, no files are dropped.
  #exclude_files: [".gz$"]

  # Optional additional fields. These field can be freely picked
  # to add additional information to the crawled log files for filtering
  #fields:
  #  level: debug
  #  review: 1

  ### Multiline options

  # Mutiline can be used for log messages spanning multiple lines. This is common
  # for Java Stack Traces or C-Line Continuation

  # The regexp Pattern that has to be matched. The example pattern matches all lines starting with [
  #multiline.pattern: ^\[

  # Defines if the pattern set under pattern should be negated or not. Default is false.
  #multiline.negate: false

  # Match can be set to "after" or "before". It is used to define if lines should be append to a pattern
  # that was (not) matched before or after or as long as a pattern is not matched based on negate.
  # Note: After is the equivalent to previous and before is the equivalent to to next in Logstash
  #multiline.match: after


#================================ General =====================================

# The name of the shipper that publishes the network data. It can be used to group
# all the transactions sent by a single shipper in the web interface.
name: $ID

# The tags of the shipper are included in their own field with each
# transaction published.
#tags: ["service-X", "web-tier"]

# Optional fields that you can specify to add additional information to the
# output.
fields:
  ossecid: $ID

#================================ Outputs =====================================

# Configure what outputs to use when sending the data collected by the beat.
# Multiple outputs may be used.

#-------------------------- Elasticsearch output ------------------------------
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["$ELASTIC_HOST"]

  # Optional protocol and basic auth credentials.
  #protocol: "https"
  username: "$ELASTIC_USER"
  password: "$ELASTIC_PASSWD"

#----------------------------- Logstash output --------------------------------
#output.logstash:
  # The Logstash hosts
  #hosts: ["localhost:5044"]

  # Optional SSL. By default is off.
  # List of root certificates for HTTPS server verifications
  #ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  #ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  #ssl.key: "/etc/pki/client/cert.key"

#================================ Logging =====================================

# Sets log level. The default log level is info.
# Available log levels are: critical, error, warning, info, debug
#logging.level: debug

# At debug level, you can selectively enable logging only for some components.
# To enable all selectors use ["*"]. Examples of other selectors are "beat",
# "publish", "service".
#logging.selectors: ["*"]

EOL

#cat /etc/filebeat/filebeat.yml

chkconfig --add filebeat
/etc/init.d/filebeat restart


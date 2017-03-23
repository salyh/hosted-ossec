#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#sudo yum install -y inotify-tools aws-cli tcpdump --enablerepo=epel

IP="172.31.2.100"
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
TPATH="/root/tcpdump"

while true; do

	mkdir -p "$TPATH"

	inotifywait -mrq -e close_write --format %w%f "$TPATH/" | while read FILE
	do
		echo "$FILE closed"
		aws s3 cp "$FILE" "s3://ossecondkunde1/123/$(basename $FILE)" --region us-west-2
	done &

	tcpdump -G 90 -C 5 -i any -K -nn -Z root -w "$TPATH/trace-h2-$(hostname)-%Y-%m-%d_%H:%M:%S.pcap" '!(src $IP)' -i eth0 &

    echo "recording ..."
	wait
	echo "Restart tcpdump"

done
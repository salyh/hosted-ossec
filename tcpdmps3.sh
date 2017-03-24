#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#sudo yum install -y inotify-tools aws-cli tcpdump --enablerepo=epel
#install redis-cli

export REDIS_HOST="ossecredis.jyu98g.0001.usw2.cache.amazonaws.com"
export TPATH="/root/tcpdump"

while true; do

	mkdir -p "$TPATH"

	inotifywait -mrq -e close_write --format %w%f "$TPATH/" | while read FILE
	do
		./redis-cli -h "$REDIS_HOST" -x HSET "$(basename $FILE)" pcap < "$FILE"
		echo "$FILE closed and stored as $(basename $FILE) in $REDIS_HOST"
        #redis-cli --raw HGET some_key image_binary > img.jpg
		#redis-cli --raw get 'imagedata' >test.png
		#./redis-cli -h "$REDIS_HOST" KEYS "trace*pcap"
		
		#aws s3 cp "$FILE" "s3://ossecondkunde1/123/$(basename $FILE)" --region us-west-2
	done &

	tcpdump -G 3 -C 1 -i any -K -nn -Z root -w "$TPATH/trace-h2-$(hostname)-%Y-%m-%d_%H:%M:%S.pcap" "(dst ! $REDIS_HOST)" &

    echo "recording ..."
	wait
	echo "Restart tcpdump"

done
#killall inotifywait tcpdump
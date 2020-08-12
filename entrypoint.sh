#!/bin/bash
set -e
echo "Configuring..."

COLLECTORS=`ls /opt/netuitive-agent/conf/collectors/ | sed 's%\.conf%%;s%Collector%%'`

if [[ ! $USE_LOCAL_CONFIG ]]; then

	sed -i -e "s/api_key\ =\ apikey/api_key = ${APIKEY}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring APIKEY: $APIKEY"

	sed -i -e "s/https/${HTTPVAR}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring HTTPVAR: $HTTPVAR"

	sed -i -e "s/level\ =\ INFO/level\ =\ ${LOGLEVEL}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring loglevel: $LOGLEVEL"

	sed -i -e "s/interval\ =\ 60/interval\ =\ ${INTERVAL}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring interval: $INTERVAL"

	sed -i -e "s/api\.app\.netuitive\.com/${APIHOST}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring APIHOST: $APIHOST"

	sed -i -e "s/# hostname\ =\ my_custom_hostname/hostname\ =\ ${DOCKER_HOSTNAME}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring HOSTNAME: $DOCKER_HOSTNAME"

	sed -i -e "s/listen_ip\ =\ 0.0.0.0/listen_ip\ =\ ${LIP}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring LISTEN_IP: $LIP"

	sed -i -e "s/listen_port\ =\ 8125/listen_port\ =\ ${LPRT}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring LISTEN_PORT: $LPRT"

	sed -i -e "s/forward_ip\ =\ 0.0.0.0/forward_ip\ =\ ${FIP}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring FORWARD_IP: $FIP"

	sed -i -e "s/forward_port\ =\ 8125/forward_port\ =\ ${FPRT}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring FORWARD_PORT: $FPRT"

	sed -i -e "s/forward\ =\ False/forward\ =\ ${FORWARD}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
	echo "Configuring FORWARD: $FORWARD"

	if [ "${APIURL}" ]; then
		sed -i -e "s%url =.*%url = ${APIURL}%g" /opt/netuitive-agent/conf/netuitive-agent.conf
		echo "Configuring URL: $APIURL"
	fi

	if [ ! -z "$TAGS" ]; then
		sed -i -e "s/# tags = tag1:tag1val, tag2:tag2val/tags =\ ${TAGS}/g" /opt/netuitive-agent/conf/netuitive-agent.conf
		echo "Configuring TAGS: $TAGS"
	fi

fi

for v in `set -o posix; set | sed 's% %:#:%g'`; do
	if [[ "${v}" == "COLLECTOR_"*  ]]; then

		FILE=`echo "${COLLECTORS}" | grep -i "^$(echo "${v}" | sed 's%^COLLECTOR_%%;s%_.*%%' | tr 'A-Z' 'a-z')$"`
		KEY=`echo "${v}" | sed 's%=.*%%;s%__%##%g;s%.*_%%;s%##%_%g' | tr 'A-Z' 'a-z'`
		VAL=`echo "${v}" | sed "s%.*=%%;s%[']%%g"`

		[ "${VAL}" == "true" ] && VAL=True
		[ "${VAL}" == "false" ] && VAL=False

		echo "Configuring ${FILE} collector ${KEY}: ${VAL}"
		sed -i "s%^${KEY}.*%${KEY} = ${VAL}%" /opt/netuitive-agent/conf/collectors/${FILE}Collector.conf

	fi
done

ln -sf /proc/1/fd/1 /opt/netuitive-agent/log/netuitive-agent.log
ln -sf /proc/1/fd/1 /opt/netuitive-agent/log/netuitive-statsd.log
ln -sf /proc/1/fd/1 /opt/netuitive-agent/log/supervisord.log

echo "Starting Services..."

export SENSORS_LIB=/opt/netuitive-agent/embedded/lib/libsensors.so
/opt/netuitive-agent/embedded/bin/python /opt/netuitive-agent/bin/netuitive-agent --foreground --configfile /opt/netuitive-agent/conf/netuitive-agent.conf&

/opt/netuitive-agent/embedded/bin/netuitive-statsd --foreground --configfile /opt/netuitive-agent/conf/netuitive-agent.conf start

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

# The default Jolokia collector configuration does not define a metrics_whitelist, so the code below couldn't set it
if [ -n "${COLLECTOR_JOLOKIA_METRICS__WHITELIST}" ]; then
	echo "" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
	echo "metrics_whitelist = ${COLLECTOR_JOLOKIA_METRICS__WHITELIST}" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
fi

if [ -n "${COLLECTOR_JOLOKIA_METRICS__BLACKLIST}" ]; then
	echo "" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
	echo "metrics_blacklist = ${COLLECTOR_JOLOKIA_METRICS__BLACKLIST}" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
fi

if [ -n "${COLLECTOR_JOLOKIA_DOMAINS}" ]; then
	echo "" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
	echo "domains = ${COLLECTOR_JOLOKIA_DOMAINS}" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
fi

# The default Jolokia collector configuration has no rewrite section
if [ -n "${COLLECTORSECTION_JOLOKIA_REWRITE}" ]; then
  echo "Configuring REWRITE section of the Jolokia collector configuration"

  echo -e "\n[rewrite]" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
  rewrite_rules=($(echo ${COLLECTORSECTION_JOLOKIA_REWRITE} | tr "%" "\n"))
  for rule in "${rewrite_rules[@]}"; do
    echo "${rule}" >> /opt/netuitive-agent/conf/collectors/JolokiaCollector.conf
  done
fi

for v in `set -o posix; set | sed 's% %:#:%g'`; do
	if [[ "${v}" == "COLLECTOR_"*  ]]; then

		FILE=`echo "${COLLECTORS}" | grep -i "^$(echo "${v}" | sed 's%^COLLECTOR_%%;s%_.*%%' | tr 'A-Z' 'a-z')$"`
		KEY=$(echo "${v}" | sed 's%=.*%%;s%__%##%g;s%.*_%%;s%##%_%g' | tr 'A-Z' 'a-z')
		VAL=$(echo "${v}" | sed  "s%.*=%%;s%[']%%g;s%\\\%\\\\\\\\\\\%g")

		[ "${VAL}" == "true" ] && VAL=True
		[ "${VAL}" == "false" ] && VAL=False

		echo "Configuring ${FILE} collector ${KEY}: ${VAL}"
		sed -i "s%^${KEY}.*%${KEY} = ${VAL}%" /opt/netuitive-agent/conf/collectors/${FILE}Collector.conf

	fi
done

test $(grep -c "ElementType" /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/handler/netuitive_handler.py) -eq 0 && \
     sed -i "s/self.element = netuitive.Element(/self.element = netuitive.Element(\n                ElementType=\"$ELEMENT_TYPE\",/" /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/handler/netuitive_handler.py && \
		 rm -f /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/handler/netuitive_handler.pyc /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/handler/netuitive_handler.pyo

# netuitive-statsd logs to this file at all times, aside from sending its logs to stdout. Hence, we don't need the log file at all.
ln -sf /dev/null /opt/netuitive-agent/log/netuitive-statsd.log

# The rotate file hander does not really work with streams
# ln -sf /proc/1/fd/1 /opt/netuitive-agent/log/netuitive-agent.log
# ln -sf /proc/1/fd/1 /opt/netuitive-agent/log/supervisord.log

echo "Starting Services..."
exec /opt/netuitive-agent/bin/supervisord --configuration /opt/netuitive-agent/conf/supervisor.conf

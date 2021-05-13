# VERSION               0.2.12
# DESCRIPTION:    Netuitive-agent in a container
# MAINTAINER Netuitive <repos@netuitive.com>

FROM      centos:8

# environment variable defaults
ENV APIHOST api.app.netuitive.com
ENV APIKEY apikey
ENV DOCKER_HOSTNAME docker-hostname
ENV ELEMENT_TYPE "SERVER"
ENV FIP "127.0.0.2"
ENV FORWARD "False"
ENV FPRT 8125
ENV HTTPVAR https
ENV INTERVAL 60
ENV LIP "0.0.0.0"
ENV LOGLEVEL INFO
ENV LPRT 8125
ENV TAGS ""

RUN  yum -y update \
  && yum install -y net-tools \
  && rpm -ivh https://github.com/art19/omnibus-netuitive-agent/releases/download/v0.8.0.art19-1/netuitive-agent-0.8.0.art19-1.el6.x86_64.rpm \
  && /sbin/chkconfig netuitive-agent off \
  && yum clean all \
  && find /opt/netuitive-agent/collectors/ -type f -name "*.py" -print0 | xargs -0 sed -i 's/\/proc/\/host_proc/g' \
  && find /var/log/ -type f -exec rm -f {} \; \
  && find /var/cache/ -type f -exec rm -f {} \;


# startup script
ADD entrypoint.sh /entrypoint.sh
ADD netuitive-agent.conf /opt/netuitive-agent/conf/netuitive-agent.conf
ADD supervisor.conf /opt/netuitive-agent/conf/supervisor.conf

RUN chmod +x /entrypoint.sh

VOLUME ["/opt/netuitive-agent/conf/"]

EXPOSE 8125

ENTRYPOINT ["/entrypoint.sh"]

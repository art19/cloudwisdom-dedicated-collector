# VERSION               0.2.12
# DESCRIPTION:    Netuitive-agent in a container
# MAINTAINER Netuitive <repos@netuitive.com>

FROM      centos:6

# environment variable defaults
ENV APIKEY apikey
ENV APIHOST api.app.netuitive.com
ENV INTERVAL 60
ENV DOCKER_HOSTNAME docker-hostname
ENV LOGLEVEL INFO
ENV HTTPVAR https
ENV LIP "0.0.0.0"
ENV LPRT 8125
ENV FIP "127.0.0.2"
ENV FPRT 8125
ENV FORWARD "False"
ENV TAGS ""
ENV ELEMENT_TYPE "SERVER"

RUN  yum -y update \
  && rpm --import https://repos.app.netuitive.com/RPM-GPG-KEY-netuitive \
  && rpm -ivh https://repos.app.netuitive.com/rpm/noarch/netuitive-repo-1-0.2.noarch.rpm \
  && yum -y install netuitive-agent-0.8.0-10.el6 \
  && /sbin/chkconfig netuitive-agent off \
  && yum clean all \
  && find /opt/netuitive-agent/collectors/ -type f -name "*.py" -print0 | xargs -0 sed -i 's/\/proc/\/host_proc/g' \
  && find /var/log/ -type f -exec rm -f {} \; \
  && find /var/cache/ -type f -exec rm -f {} \;


# startup script
ADD entrypoint.sh /entrypoint.sh
ADD netuitive-agent.conf /opt/netuitive-agent/conf/netuitive-agent.conf
RUN chmod +x /entrypoint.sh

VOLUME ["/opt/netuitive-agent/conf/"]

EXPOSE 8125

ENTRYPOINT ["/entrypoint.sh"]

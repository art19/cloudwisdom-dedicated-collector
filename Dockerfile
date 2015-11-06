# VERSION               0.1.8
# DESCRIPTION:    Netuitive-agent in a container
# MAINTAINER Netuitive <repos@netuitive.com>

FROM      centos:6

# environment variable defaults
ENV APIKEY apikey
ENV APIHOST api.app.netuitive.com
ENV INTERVAL 60
ENV DOCKER_HOSTNAME docker-hostname
ENV LOGLEVEL WARN
ENV HTTPVAR https

# install updates and build tools
ADD entrypoint.sh /

RUN  yum -y update \
  && chmod +x /entrypoint.sh \
  && rpm --import https://repos.app.netuitive.com/RPM-GPG-KEY-netuitive \
  && rpm -ivh https://repos.app.netuitive.com/rpm/noarch/netuitive-repo-1-0.2.noarch.rpm \
  && yum -y install netuitive-agent \
  && /sbin/chkconfig netuitive-agent off \
  && yum clean all \
  && cp /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/utils/log.py /opt/netuitive-agent/embedded/lib/python2.7/site-packages/diamond/utils/log.py.tpl \
  && yum clean all \
  && find /var/log/ -type f -exec rm -f {} \; \
  && find /var/cache/ -type f -exec rm -f {} \;

ADD netuitive-agent.conf /opt/netuitive-agent/conf/netuitive-agent.conf.tpl

# startup script
RUN chmod +x /entrypoint.sh

#start
ENTRYPOINT ["/entrypoint.sh"]

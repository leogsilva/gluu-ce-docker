FROM ubuntu:14.04

#
# docker run --privileged --cap-add ALL -v /lib/modules:/lib/modules -p 443:443 --rm -ti
MAINTAINER Leonardo <leogsilva@gmail.com>

RUN apt-get update
RUN apt-get install -y curl wget supervisor apt-transport-https

RUN echo "deb https://repo.gluu.org/ubuntu/ trusty main" > /etc/apt/sources.list.d/gluu-repo.list
RUN curl https://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -
RUN apt-get update

ENV GLUU_VERSION 3.0.2
ENV GLUU_DEB_URL https://repo.gluu.org/ubuntu/pool/main/trusty/gluu-server-${GLUU_VERSION}_9-1~trusty+Ub14.04_amd64.deb

WORKDIR /
COPY run.sh .
RUN wget -q ${GLUU_DEB_URL} -O gluu-server-${GLUU_VERSION}_9-1~trusty+Ub14.04_amd64.deb ; dpkg -i gluu-server-${GLUU_VERSION}_9-1~trusty+Ub14.04_amd64.deb
COPY setup.properties /opt/gluu-server-${GLUU_VERSION}/install/community-edition-setup/
CMD chmod +x /run.sh && /run.sh install

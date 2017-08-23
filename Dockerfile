FROM ubuntu:14.04

# https://repo.gluu.org/ubuntu/pool/main/trusty/gluu-server-3.0.2_9-1~trusty+Ub14.04_amd64.deb
# docker run --privileged --cap-add ALL -v /lib/modules:/lib/modules -p 443:443 --rm -ti
MAINTAINER Shouro <leogsilva@gmail.com>

RUN apt-get update
RUN apt-get install -y curl wget supervisor apt-transport-https

RUN echo "deb https://repo.gluu.org/ubuntu/ trusty main" > /etc/apt/sources.list.d/gluu-repo.list
RUN curl https://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -
RUN apt-get update
COPY gluu-server-3.0.2_9-1~trusty+Ub14.04_amd64.deb .
WORKDIR /
COPY run.sh .
RUN dpkg -i gluu-server-3.0.2_9-1~trusty+Ub14.04_amd64.deb
COPY setup.properties /opt/gluu-server-3.0.2/install/community-edition-setup/
CMD chmod +x /run.sh && /run.sh install

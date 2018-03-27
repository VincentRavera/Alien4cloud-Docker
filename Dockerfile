FROM ubuntu:trusty

LABEL maintainer Vincent RAVERA <ravera.vincent@gmail.com>

RUN apt-get update

WORKDIR /root/

# Alien4Cloud prerequisites
# Misc
RUN apt-get install -y curl wget git python python3

# JAVA
COPY jre-8u161-linux-x64.tar.gz /opt/
RUN cd /opt/; tar -zxvf jre-8u161-linux-x64.tar.gz
ENV JAVA_HOME="/opt/jre1.8.0_161/"

# Docker
RUN apt-get install -y apt-transport-https ca-certificates software-properties-common
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get install -y docker-ce



# Install of vim
RUN apt-get install -y vim

#COPY VIM_Docker_Builded.tgz /root/
#
#RUN tar -zxvf VIM_Docker_Builded.tgz
#
#RUN apt-get install -y zsh
#
#RUN env git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
#
#COPY .zshrc /root

EXPOSE 8088

CMD curl -s https://raw.githubusercontent.com/alien4cloud/alien4cloud.github.io/sources/files/1.4.0/getting_started.sh | bash

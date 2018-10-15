FROM signiant/docker-jenkins-centos-base:centos7-java8
MAINTAINER devops@signiant.com

EXPOSE 8000
EXPOSE 9000

ENV BUILD_USER bldmgr
ENV BUILD_USER_GROUP users

# Set the timezone
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

# Install yum packages required for build node
COPY yum-packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN npm install -g npm
RUN yum install -y -q `cat /tmp/yum.packages.list`

# Install yum development tools
RUN yum groupinstall -y -q "Development Tools"

# Install Compass
RUN gem install json_pure
RUN gem update --system

# Install the latest version of git
RUN cd /tmp && \
    wget https://github.com/git/git/archive/v2.7.0.tar.gz && \
    tar xvfz ./v2.7.0.tar.gz && \
    cd git-2.7.0 && \
    make configure && \
    ./configure --prefix=/usr && \
    make && \
    make install

# Install Python 2.7.X for Umpire
RUN cd /tmp && \
    wget https://www.python.org/ftp/python/2.7.11/Python-2.7.11.tgz && \
    tar xvfz Python-2.7.11.tgz && \
    cd Python-2.7.11 && \
    ./configure --prefix=/usr/local && \
    make && \
    make altinstall

# Install pip
RUN easy_install -q pip && \
    pip install --upgrade pip

ENV UMPIRE_VERSION 0.5.3
# Install umpire
RUN pip2.7 install umpire==${UMPIRE_VERSION}

# Install golang 1.11
RUN wget https://storage.googleapis.com/golang/go1.11.1.linux-amd64.tar.gz -O /tmp/go1.11.1.linux-amd64.tar.gz
RUN sudo tar -C /usr/local -xzf /tmp/go1.11.1.linux-amd64.tar.gz
RUN export GO111MODULE=on

#Install glide
RUN wget https://github.com/Masterminds/glide/releases/download/v0.12.3/glide-v0.12.3-linux-amd64.tar.gz -O /tmp/glide-v0.12.3-linux-amd64.tar.gz
RUN mkdir /tmp/glide-v0.12.3-linux-amd64
RUN tar -C /tmp/glide-v0.12.3-linux-amd64 -xzf /tmp/glide-v0.12.3-linux-amd64.tar.gz
RUN cp /tmp/glide-v0.12.3-linux-amd64/linux-amd64/glide /usr/local/bin/

# Make sure anything/everything we put in the build user's home dir is owned correctly
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER

EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

# Default Jenkins Slave Name
ENV SLAVE_ID JAVA_NODE
ENV SLAVE_OS Linux

ADD start.sh /
RUN chmod 777 /start.sh

CMD ["sh", "/start.sh"]

FROM ghcr.io/linuxserver/baseimage-alpine:3.16

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    logrotate \
    nano \
    netcat-openbsd \
    sudo && \
  echo "**** install openssh-server ****" && \
  if [ -z ${OPENSSH_RELEASE+x} ]; then \
    OPENSSH_RELEASE=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp && \
    awk '/^P:openssh-server-pam$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    openssh-client==${OPENSSH_RELEASE} \
    openssh-server-pam==${OPENSSH_RELEASE} \
    openssh-sftp-server==${OPENSSH_RELEASE} && \
  echo "**** setup openssh environment ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  usermod --shell /bin/bash abc && \
  rm -rf \
    /tmp/* \
  echo "**** install golang ****" \
  wget https://golang.org/dl/go1.18.1.linux-amd64.tar.gz \
  tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz \
  export PATH=$PATH:/usr/local/go/bin \
  touch ~/.bash_profile \
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bash_profile \
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile \
  go version \
  echo "**** install php ****" \
  apk add php \
  php -v \
  apk add php-gd \
  apk add php-curl \
  apk add php-sqlite3 \
  apk add php-pgsql \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  php composer-setup.php \
  php -r "unlink('composer-setup.php');" \
  mv composer.phar /usr/local/bin/composer \
  echo "**** install node ****"
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash \
  nvm install latest \
  nodepath=$(which node); sudo ln -s $nodepath /usr/bin/node
  
# add local files
COPY /root /

EXPOSE 2222

VOLUME /config

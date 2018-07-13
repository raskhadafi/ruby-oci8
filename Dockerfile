FROM       oraclelinux:7-slim
MAINTAINER Roman Simecek <raskhadafi@good2go.ch>

ENV LANG                   en_US.utf8
ENV LC_ALL                 en_US.utf8
ENV LC_CTYPE               en_US.utf8
ENV NLS_LANG               American_America.UTF8
ENV PKG_CONFIG_PATH        /usr/local/lib/pkgconfig
ENV INSTANT_CLIENT_VERSION 12.2.0.1.0-1
ENV LD_LIBRARY_PATH        /usr/lib/oracle/12.2/client64/lib:$LD_LIBRARY_PATH
ENV RUBY_MAJOR             2.4
ENV RUBY_VERSION           2.4.4

COPY "oracle-instantclient12.2-*-$INSTANT_CLIENT_VERSION.x86_64.rpm" $HOME/

RUN yum -y update && \
    yum -y groupinstall 'Development Tools' && \
    yum -y install \
      libcurl-devel \
      openssl-devel \
      readline-devel \
      openssl-devel \
      zlib-devel \
      wget \
      which \
      libaio \
      git && \
    rpm -i "oracle-instantclient12.2-basic-$INSTANT_CLIENT_VERSION.x86_64.rpm" && \
    rpm -i "oracle-instantclient12.2-devel-$INSTANT_CLIENT_VERSION.x86_64.rpm" && \
    rpm -i "oracle-instantclient12.2-sqlplus-$INSTANT_CLIENT_VERSION.x86_64.rpm" && \
    rm -rf oracle-instantclient12.2*.rpm && \
    yum -y clean all && \
    rm -rf /var/cache/yum

RUN mkdir -p /usr/local/etc \
    && { \
        echo 'install: --no-document'; \
        echo 'update: --no-document'; \
        echo ':ssl_verify_mode: 0'; \
    } >> /usr/local/etc/gemrc

RUN yum -y update && yum -y install ruby && yum clean all \
    && mkdir -p /usr/src/ruby \
    && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
        | tar -xjC /usr/src/ruby --strip-components=1 \
    && cd /usr/src/ruby \
    && autoconf \
    && ./configure --disable-install-doc \
    && make -j"$(nproc)" \
    && yum remove -y ruby \
    && make install \
    && rm -r /usr/src/ruby \
    && yum -y clean all \
    && rm -rf /var/cache/yum

RUN gem update --system && \
    bundle config --global silence_root_warning 1

RUN yum -y update && \
    yum -y install \
      tcl-devel \
      libpng-devel \
      libjpeg-devel \
      ghostscript-devel \
      bzip2-devel \
      freetype-devel \
      libtiff-devel \
      libpng12-devel.i686 \
      ImageMagick-devel && \
    wget ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick-6.9.*.tar.gz && \
    tar zxvf ImageMagick-*.tar.gz && \
    cd ImageMagick-* && \
    ./configure && \
    make && \
    make install && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done

ENV NODE_VERSION 9.3.0
ENV SWISSMATCH_DATA /swissmatch

RUN mkdir $SWISSMATCH_DATA
COPY "locations_*.binary" $SWISSMATCH_DATA/

RUN ARCH= && dpkgArch="$(arch)" \
  && case "${dpkgArch##*-}" in \
    x86_64) ARCH='x64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN cd /etc/pki/ca-trust/source/anchors/ && \
    wget https://www.digicert.com/CACerts/DigiCertSHA2SecureServerCA.crt && \
    update-ca-trust extract

RUN wget http://dl.google.com/linux/chrome/rpm/stable/x86_64//google-chrome-stable-67.0.3396.99-1.x86_64.rpm && \
    yum -y install google-chrome-stable-67.0.3396.99-1.x86_64.rpm && \
    rm -f google-chrome-stable-67.0.3396.99-1.x86_64.rpm

RUN wget -N http://chromedriver.storage.googleapis.com/2.40/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -f chromedriver_linux64.zip

CMD ["irb"]

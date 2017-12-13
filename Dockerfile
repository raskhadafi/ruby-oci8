FROM       oraclelinux
MAINTAINER Roman Simecek <raskhadafi@good2go.ch>

ENV LANG                   de_CH.utf8
ENV LC_CTYPE               de_CH.utf8
ENV PKG_CONFIG_PATH        /usr/local/lib/pkgconfig
ENV INSTANT_CLIENT_VERSION 12.2.0.1.0-1
ENV LD_LIBRARY_PATH        /usr/lib/oracle/12.2/client64/lib:$LD_LIBRARY_PATH
ENV RUBY_MAJOR             2.3
ENV RUBY_VERSION           2.3.5

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
    wget ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick-6.9.9-26.tar.gz && \
    tar zxvf ImageMagick-*.tar.gz && \
    cd ImageMagick-* && \
    ./configure && \
    make && \
    make install && \
    yum clean all && \
    rm -rf /var/cache/yum

CMD ["irb"]

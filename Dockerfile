FROM rocker/r-ver:3.5.0

ARG RSTUDIO_VERSION
## Comment the next line to use the latest RStudio Server version by default
ENV RSTUDIO_VERSION=${RSTUDIO_VERSION:-1.1.456}
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

## Install and configure the base system
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    gdebi-core \
    git \
    libapparmor1 \
    libc6 \
    libcurl4-openssl-dev \
    libedit2 \
    liblzma-dev \
    libpcre++-dev \
    libssl-dev \
    libssl1.0.2 \
    libxml2-dev \
    libbz2-dev \
    lsb-release \
    multiarch-support \
    net-tools \
    nginx \
    procps \
    psmisc \
    python \
    python-pip \
    python-setuptools \
    sudo \
    wget \
    zlib1g-dev \
  && pip install -U setuptools pip \
  && RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
  && [ -z "$RSTUDIO_VERSION" ] && RSTUDIO_VERSION=$RSTUDIO_LATEST || true \
  && wget -q https://download2.rstudio.org/rstudio-server-stretch-${RSTUDIO_VERSION}-amd64.deb \
  && gdebi -n rstudio-server-stretch-${RSTUDIO_VERSION}-amd64.deb \
  && apt-get autoremove -y \
  && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD rsession.conf /etc/rstudio/rsession.conf

# ENV variables to replace conf file from Galaxy
ENV DEBUG=false \
    GALAXY_WEB_PORT=10000 \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    API_KEY=none \
    HISTORY_ID=none \
    REMOTE_HOST=none \
    GALAXY_URL=none \
    RSTUDIO_FULL=1

ADD ./startup.sh /startup.sh
ADD ./monitor_traffic.sh /monitor_traffic.sh
ADD ./proxy.conf /proxy.conf
ADD ./GalaxyConnector /tmp/GalaxyConnector
ADD ./packages-gx.R /tmp/packages-gx.R
ADD ./rserver.conf /etc/rstudio/rserver.conf

# /import will be the universal mount-point for IPython
#RUN apt-get update && apt-get install -y r-base-dev
# The Galaxy instance can copy in data that needs to be present to the Rstudio webserver
RUN chmod +x /startup.sh && \
    Rscript /tmp/packages-gx.R && \
    pip install galaxy-ie-helpers && \
    groupadd -r rstudio -g 1450 && \
    mkdir /import && \
    useradd -u 1450 -r -g rstudio -d /import -c "RStudio User" \
        -p $(openssl passwd -1 rstudio) rstudio && \
    chown -R rstudio:rstudio /import

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
COPY ./Rprofile.site /usr/lib/R/etc/Rprofile.site

# Start RStudio
CMD /startup.sh
EXPOSE 80

FROM ubuntu:focal-20210416

ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN set -ex; \
    apt-get update -qq && apt-get -y -qq dist-upgrade > /dev/null \
    \
    && mkdir -p /usr/share/man/man1 \
    && apt-get install -y -qq --no-install-recommends apt-utils \
        sudo locales software-properties-common \
        build-essential \
        wget curl zip unzip bzip2 llvm git vim gnupg \
        libncurses5-dev ca-certificates netbase netcat \
        python3 \
        python3-dev \
        python3-pip \
        python3-pycurl \
        python3-venv \
        nodejs npm yarn \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && npm install n -g \
    && n stable

RUN python3.8 -m venv /venv

ENV PATH=/venv/bin:/usr/local/bin:$PATH

RUN python --version \
    && pip install --quiet --upgrade \
        pip \
        setuptools \
        jupyterlab \
        ipywidgets \
        perspective-python

RUN jupyter labextension install @finos/perspective-jupyterlab

RUN adduser jovyan --uid 1000 --gid 100 --disabled-password --gecos '' --shell /bin/bash \
    && adduser jovyan sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

EXPOSE 8888
ENV HOME=/home/jovyan
USER jovyan
WORKDIR $HOME
RUN mkdir -p $HOME/work
WORKDIR $HOME/work

CMD jupyter lab --ip=* --port=8888 --no-browser --allow-root
FROM ubuntu:focal-20210416

# Notice: part of this code is from jupyter project
LABEL MAINTAINER Roger Mähler <roger dot mahler at umu dot se>

ARG LAB_USER="jovyan"
ARG LAB_UID="1000"
ARG LAB_GID="100"
ARG LAB_PORT=8888

ARG TINI_VERSION=v0.18.0
ARG JUPYTERHUB_VERSION

ARG GITHUB_ORG
ARG GITHUB_REPOSITORY
ARG PYPI_PACKAGE

ENV LAB_PORT=${LAB_PORT} \
    LAB_USER=$LAB_USER \
    LAB_UID=$LAB_UID \
    LAB_GID=$LAB_GID

ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN set -ex; \
    \
    apt-get update -qq && apt-get -y -qq dist-upgrade > /dev/null \
    \
    && mkdir -p /usr/share/man/man1 \
    && apt-get install -y -qq --no-install-recommends apt-utils \
        sudo locales software-properties-common \
        build-essential \
        wget curl zip unzip bzip2 llvm git vim gnupg \
        libssl-dev libopenblas-base zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev  \
        libncurses5-dev ca-certificates netbase netcat \
        python3 \
        python3-dev \
        python3-pip \
        python3-pycurl \
        python3-venv \
        nodejs npm yarn \
        fonts-liberation > /dev/null \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && npm install n -g \
    && n stable

RUN python3.8 -m venv /venv

ENV PATH=/venv/bin:/usr/local/bin:$PATH

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini

RUN chmod +x /usr/local/bin/tini

RUN python --version \
    && pip install --quiet --upgrade pip \
    && pip install --quiet jupyterhub==${JUPYTERHUB_VERSION}

ARG PYPI_PACKAGE_VERSION

RUN pip install --quiet ${PYPI_PACKAGE}==${PYPI_PACKAGE_VERSION}

RUN \
    python -m nltk.downloader -d /usr/local/share/nltk_data stopwords punkt sentiwordnet \
    \
    && pip install --quiet spacy-lookups-data \
    && python -m spacy download en_core_web_sm \
    && python -m spacy download en_core_web_md \
    && python -m spacy link en_core_web_sm en --force \
    && mkdir -p /data

RUN jupyter labextension install ipyaggrid @finos/perspective-jupyterlab

ENV NLTK_DATA=/usr/local/share/nltk_data

ENTRYPOINT ["tini", "-g", "--"]

RUN adduser $LAB_USER --uid $LAB_UID --gid $LAB_GID --disabled-password --gecos '' --shell /bin/bash \
    && adduser $LAB_USER sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN  npm cache clean --force \
    && jupyter lab clean \
    && pip cache purge

# root@2321233364af:/usr/local/lib/python3.8/site-packages# du -s spacy_lookups_data/data/* | sort -n

EXPOSE ${LAB_PORT}

ENV HOME=/home/$LAB_USER
USER $LAB_USER
WORKDIR $HOME

RUN mkdir -p $HOME/work

WORKDIR $HOME/work

ADD https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPOSITORY}/git/refs/heads/master version.json

RUN git clone https://github.com/${GITHUB_ORG}/${GITHUB_REPOSITORY}.git \
    && cd ${GITHUB_REPOSITORY} \
    && rm -rf tests scripts .git* .devcontainer* .flake* .pre* .pylint* .travis* .isort* .docker* \
        *oetry* pyproject* pyright* pytest* run* environment.yml westac \
        Makefile requirements.txt NOTE*.md README*.md setup.py ipynb2py.sh

COPY --chown=$LAB_USER:users data $HOME/work/${GITHUB_REPOSITORY}/data

# CMD ["jupyterhub-singleuser"]
# CMD jupyter lab --ip=* --port=${LAB_PORT} --no-browser --notebook-dir=$HOME/work --allow-root
CMD jupyter lab --ip=* --port=${LAB_PORT} --no-browser --allow-root

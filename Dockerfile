ARG JUPYTERHUB_VERSION

FROM jupyterhub/jupyterhub:${JUPYTERHUB_VERSION}
#$JUPYTERHUB_VERSION

# Update and install some package
RUN apt-get update && apt-get install -yq --no-install-recommends \
	vim git curl wget  \
    libmemcached-dev \
    libsqlite3-dev \
    libzmq3-dev \
    make nodejs node-gyp npm \
    pandoc \
    sqlite3 \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*  && hash -r


RUN pip install --upgrade pip \
    && pip install --quiet \
        jupyterhub-idle-culler \
        psycopg2-binary \
        netifaces \
        dockerspawner \
        oauthenticator \
        jhub_cas_authenticator

WORKDIR /srv

CMD ["jupyterhub", "-f", "/etc/jupyterhub/jupyterhub_config.py"]

# FIXME #2 Upgrade JupyterHub
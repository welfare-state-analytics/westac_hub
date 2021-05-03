# JupyterHub configuration
#
## If you update this file, do not forget to delete the `$(HUB_HOST_VOLUME_NAME)` volume before restarting the jupyterhub service:
##     docker volume rm $(HUB_HOST_VOLUME_NAME)
## or, if you changed the COMPOSE_PROJECT_NAME to <name>:
##    docker volume rm <name>$(HUB_HOST_VOLUME_NAME)

import os
import sys
import oauthenticator

# try:
#     from jupyter_client.localinterfaces import public_ips
# except:
#     from IPython.utils.localinterfaces  import public_ips

network_name = os.environ['HUB_NETWORK_NAME']
spawn_cmd = os.environ.get('DOCKER_SPAWN_CMD', "start-singleuser.sh")
notebook_dir = os.environ.get('LAB_NOTEBOOK_DIR') or '/home/jovyan'
data_dir = os.environ.get('HUB_HOST_VOLUME_FOLDER', '/data')
config_dir = os.environ.get('HUB_CONFIG_FOLDER', '/etc/jupyterhub')

# def get_ip():
#     import netifaces
#     try:
#         docker0 = netifaces.ifaddresses('docker0')
#         docker0_ipv4 = docker0[netifaces.AF_INET][0]
#         return docker0_ipv4['addr']
#     except:
#         return os.environ['HUB_IP']

def read_userlist():
    allowed_users, admin = set(), set()
    filename = os.path.join(config_dir, "userlist")
    assert os.path.isfile(filename), "userlist expected at {}".format(filename)
    with open(filename, "r") as fi:
        lines = [
            x.split() for x in [ y.strip() for y in fi.readlines() ]
                if len(x) > 0 and not x.startswith('#')
        ]
    allowed_users = set([ x[0] for x in lines ])
    admin = set([ x[0] for x in lines if len(x) > 1 and x[1] == "admin" ])
    return allowed_users, admin

c = get_config()

c.JupyterHub.services = [
    {
        'name': 'idle-culler',
        'admin': True,
        'command': [
            sys.executable,
            '-m', 'jupyterhub_idle_culler',
            '--timeout=3600'
        ],
    }
]

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.JupyterHub.admin_access = True
c.JupyterHub.hub_ip = '0.0.0.0'                                             # The public facing ip of the whole application (the proxy)
c.JupyterHub.hub_connect_ip = os.environ['HUB_IP']                          # The ip for this process

c.JupyterHub.authenticator_class = oauthenticator.github.GitHubOAuthenticator
c.JupyterHub.cookie_secret_file = os.path.join(data_dir, 'jupyterhub_cookie_secret')

c.GitHubOAuthenticator.oauth_callback_url = os.environ['OAUTH_CALLBACK_URL']
c.GitHubOAuthenticator.client_id = os.environ['OAUTH_CLIENT_ID']
c.GitHubOAuthenticator.client_secret = os.environ['OAUTH_CLIENT_SECRET']

c.Authenticator.allowed_users, c.Authenticator.admin_users = read_userlist()

c.DockerSpawner.image = os.environ['DOCKER_JUPYTER_CONTAINER']
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name
c.DockerSpawner.notebook_dir = '/home/jovyan/work'                          # notebook_dir

c.DockerSpawner.volumes = {
    'jupyterhub-westac-user-{username}': '/home/jovyan/work',
    '/data/westac': {                                                       # path on host
        "bind": '/data/westac',                                             # path in docker instance
        "mode": "rw"
    }
}
c.DockerSpawner.remove_containers = True                                    # Remove containers once they are stopped
c.DockerSpawner.host_ip = "0.0.0.0"

c.DockerSpawner.name_template = "jupyterhub-westac-{username}"

# c.DockerSpawner.links={network_name: network_name}

c.Spawner.default_url = '/lab'
# c.Spawner.cpu_limit = 1
c.Spawner.mem_limit = '5G'
c.Spawner.notebook_dir = notebook_dir

# Debug settimgs
c.JupyterHub.debug_proxy = True
c.DockerSpawner.debug = True
c.JupyterHub.log_level = 10
c.Spawner.cmd = ['jupyterhub-singleuser', '--debug']
c.Authenticator.auto_login = False

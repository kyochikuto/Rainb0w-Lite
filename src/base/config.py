import os

from utils.helper import get_public_ip

# Server info
PUBLIC_IP = get_public_ip()

# Path
RAINB0W_BACKUP_DIR = f"{os.path.expanduser('~')}/Rainb0w_Backup"
RAINB0W_HOME_DIR = f"{os.path.expanduser('~')}/Rainb0w_Lite_Home"
RAINB0W_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/rainb0w_config.toml"
RAINB0W_USERS_FILE = f"{RAINB0W_HOME_DIR}/rainb0w_users.toml"
SINGBOX_CONFIG_FILE = f"{RAINB0W_HOME_DIR}/sing-box/etc/config.json"
SINGBOX_DOCKER_COMPOSE_FILE = f"{RAINB0W_HOME_DIR}/sing-box/docker-compose.yml"
WARP_CONF_FILE = (
    f"{os.path.expanduser('~')}/.cache/warp-plus/primary/wgcf-identity.json"
)

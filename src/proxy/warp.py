import os
from typing import Optional

from base.config import WARP_CONF_FILE
from utils.helper import load_json, save_json
from utils.os_utils import run_system_cmd


def configure_warp(config_file_path: str, warp_conf_file: str):
    warp_conf = load_json(warp_conf_file)
    proxy_conf = load_json(config_file_path)

    proxy_conf["endpoints"][0]["private_key"] = warp_conf["private_key"]

    save_json(proxy_conf, config_file_path)

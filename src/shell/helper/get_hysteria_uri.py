#!/usr/bin/env python3

import os
import sys
from pathlib import Path

import toml
from rich import print

SRC_DIR = Path(__file__).resolve().parents[2]
sys.path.append(str(SRC_DIR))

from base.config import SINGBOX_CONFIG_FILE
from proxy.hysteria import get_hysteria_share_uri

"""
This script returns the Hysteria share URIs for the first user added during installation
"""
users_file_handle = open(
    f"{os.path.expanduser('~')}/Rainb0w_Lite_Home/rainb0w_users.toml", "r"
)

rainb0w_users = toml.load(users_file_handle)
username = rainb0w_users["users"][0]["name"]

print(get_hysteria_share_uri(username, SINGBOX_CONFIG_FILE))

users_file_handle.close()

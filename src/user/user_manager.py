import os
import random
from os import urandom
from os.path import exists
from random import randint
from uuid import uuid4

from rich import print

from base.config import PUBLIC_IP
from proxy.hysteria import (
    get_hysteria_share_uri,
    hysteria_add_user,
    hysteria_remove_user,
)
from proxy.reality import get_reality_share_uri, reality_add_user, reality_remove_user
from utils.helper import (
    gen_qrcode,
    gen_random_string,
    load_json,
    load_toml,
    load_txt_file,
    load_yaml,
    print_txt_file,
    remove_dir,
    save_json,
    save_qrcode,
    save_toml,
    save_yaml,
)


def get_users(rainb0w_users_file: str) -> list:
    rainb0w_users = load_toml(rainb0w_users_file)
    if "users" in rainb0w_users:
        return rainb0w_users["users"]
    else:
        rainb0w_users["users"] = []
        return rainb0w_users["users"]


def create_new_user(username: str):
    password = gen_random_string(randint(8, 12))
    uuid = str(uuid4())
    user_info = {"name": username, "password": password, "uuid": uuid}
    return user_info


def add_user_to_proxies(user_info: dict, config_file: str):
    print(f"Adding user [green]'{user_info['name']}'[/green]")
    reality_add_user(user_info, config_file)
    hysteria_add_user(user_info, config_file)


def add_user_to_list(
    user_info: dict,
    rainb0w_users_file: str,
):
    rainb0w_users = load_toml(rainb0w_users_file)
    users = rainb0w_users.setdefault("users", [])
    users.append(user_info)
    save_toml(rainb0w_users, rainb0w_users_file)


def remove_user(username: str, config_file: str, rainb0w_users_file: str):
    print(f"Removing user [red]'{username}'[/red]")
    reality_remove_user(username, config_file)
    hysteria_remove_user(username, config_file)
    rainb0w_users = load_toml(rainb0w_users_file)
    client_to_remove = next(
        (c for c in rainb0w_users if c.get("name") == username), None
    )
    if client_to_remove:
        rainb0w_users.remove(client_to_remove)
        save_toml(rainb0w_users, rainb0w_users_file)


def print_client_info(username: str, config_file: str, rainb0w_config_file: str):
    print("=" * 60)
    print("\n*********************** REALITY ***********************")
    print(get_reality_share_uri(username, config_file, rainb0w_config_file))
    print("\n*********************** Hysteria ***********************")
    print(get_hysteria_share_uri(username, config_file))
    print("=" * 60)
    print(
        """\n
[bold yellow]NOTE: DO NOT SHARE THESE LINKS AND INFORMATION OVER SMS OR DOMESTIC MESSENGERS,
USE EMAILS OR OTHER SECURE WAYS OF COMMUNICATION INSTEAD![/bold yellow]
    """.lstrip()
    )


def prompt_username():
    username = input("\nEnter a username for your first user: ")
    while not username or not username.isascii() or not username.islower():
        print(
            "\nInvalid username! Enter only ASCII characters and numbers in lowercase."
        )
        username = input("Enter a username for your first user: ")

    return username

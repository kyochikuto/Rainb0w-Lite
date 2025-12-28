import random
import re
from typing import Optional, Tuple

from rich import print

from base.config import PUBLIC_IP
from utils.cert_utils import is_domain, is_subdomain
from utils.helper import load_json, load_toml, load_yaml, save_json


def reality_add_user(user_info: dict, config_file: str):
    config = load_json(config_file)
    reality_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "REALITY"),
        None,
    )
    if reality_inbound is None:
        raise ValueError('No inbound with tag "REALITY" found in the configuration.')

    reality_inbound.setdefault("users", [])
    reality_inbound.setdefault("tls", {}).setdefault("reality", {})

    new_user = {
        "name": user_info["name"],
        "uuid": user_info["uuid"],
        "flow": "xtls-rprx-vision",
    }

    reality_inbound["users"].append(new_user)

    save_json(config, config_file)


def reality_remove_user(username: str, config_file: str):
    config = load_json(config_file)
    reality_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "REALITY"),
        None,
    )
    if reality_inbound is None:
        raise ValueError('No inbound with tag "REALITY" found in the configuration.')

    users = reality_inbound.get("users", [])

    client_to_remove = next((c for c in users if c.get("name") == username), None)
    if client_to_remove:
        users.remove(client_to_remove)

    save_json(config, config_file)


def configure_reality(
    proxy_config: dict,
    config_file: str,
):
    print("Configuring REALITY...")
    config = load_json(config_file)
    reality_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "REALITY"),
        None,
    )
    if reality_inbound is None:
        raise ValueError('No inbound with tag "REALITY" found in the configuration.')

    tls = reality_inbound.setdefault("tls", {})
    reality = tls.setdefault("reality", {})
    handshake = reality.setdefault("handshake", {})

    reality_inbound["listen_port"] = int(proxy_config["PORT"])
    tls["server_name"] = proxy_config["SNI"]
    handshake["server"] = proxy_config["SNI"]
    handshake["server_port"] = int(proxy_config["PORT"])
    reality["private_key"] = proxy_config["PRIVATE_KEY"]
    reality["short_id"] = proxy_config["SHORT_ID"]

    save_json(config, config_file)


def reset_reality_sni(
    sni: str,
    port: int,
    config_file: str,
):
    config = load_json(config_file)

    reality_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "REALITY"),
        None,
    )
    if reality_inbound is None:
        raise ValueError('No inbound with tag "REALITY" found in the configuration.')

    tls = reality_inbound.setdefault("tls", {})
    reality = tls.setdefault("reality", {})
    handshake = reality.setdefault("handshake", {})

    tls["server_name"] = f"{sni}:{port}"
    handshake["server"] = sni
    handshake["port"] = port

    save_json(config, config_file)


def get_reality_share_uri(username: str, config_file: str, rainb0w_config_file: str):
    rainb0w_config = load_toml(rainb0w_config_file)
    config = load_json(config_file)
    reality_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "REALITY"),
        None,
    )
    if reality_inbound is None:
        raise ValueError('No inbound with tag "REALITY" found in the configuration.')

    users = reality_inbound.get("users", [])
    tls = reality_inbound.get("tls", {})
    reality = tls.get("reality", {})
    handshake = reality.get("handshake", {})

    user_info = next((c for c in users if c.get("name") == username), None)
    if user_info:
        return f"vless://{user_info['uuid']}@{PUBLIC_IP}:{reality_inbound['listen_port']}?security=reality&encryption=none&pbk={rainb0w_config['REALITY']['PUBLIC_KEY']}&headerType=none&fp=chrome&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni={handshake['server']}&sid={reality['short_id']}#{username}%20[REALITY]".strip()
    else:
        raise ValueError(f'User "{username}" not found in the configuration.')


def prompt_reality_destination_server() -> Tuple[str, int]:
    """
    Keep asking the user for a value until it matches
    the ``DOMAIN.TLD:PORT`` pattern.
    """
    while True:
        print(
            "Enter the SNI destination for the REALITY proxy as in `[yellow](SUB.)DOMAIN.TLD[/yellow]:[green]PORT[/green]`"
        )
        user_input = input("SNI destination: ").strip()
        ok, domain, port = validate_domain_port(user_input)

        if ok:
            print(f"✅  Accepted → domain={domain!r}, port={port}")
            return (
                domain,
                port,
            )  # ty:ignore[invalid-return-type]
        else:
            print(
                "❌  Invalid format.  Expected ``DOMAIN.TLD:PORT`` "
                "with a numeric port between 1‑65535."
            )


def validate_domain_port(value: str) -> Tuple[bool, Optional[str], Optional[int]]:
    """
    Validate that *value* matches the pattern ``DOMAIN.TLD:PORT``.

    Returns a tuple ``(is_valid, domain, port)`` where:
    * ``is_valid`` – ``True`` if the string conforms to the pattern **and**
      the numeric port is in the range 1‑65535.
    * ``domain`` – the extracted domain part when valid, otherwise ``None``.
    * ``port`` – the extracted port as an ``int`` when valid, otherwise ``None``.
    """
    _PATTERN = re.compile(
        r"""
        ^                                   # start of string
        (?P<domain>
            (?:[a-zA-Z0-9]                  # first char of a label
                (?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?   # optional middle chars
            \.)+                            # dot after each label (at least one)
            [a-zA-Z]{2,63}                  # top‑level domain
        )
        :                                   # literal colon
        (?P<port>\d{1,5})                    # 1‑5 digits
        $                                   # end of string
        """,
        re.VERBOSE,
    )
    match = _PATTERN.fullmatch(value.strip())
    if not match:
        return False, None, None

    domain = match.group("domain")
    port = int(match.group("port"))

    # Port numbers must be within the TCP/UDP range
    if not (1 <= port <= 65535):
        return False, None, None

    return True, domain, port

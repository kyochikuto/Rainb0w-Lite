from utils.cert_utils import is_domain, is_subdomain
from utils.helper import (
    gen_random_string,
    load_json,
    load_yaml,
    save_json,
    save_yaml,
    write_txt_file,
)


def configure_hysteria(
    proxy_config: dict,
    config_file: str,
):
    print("Configuring Hysteria...")
    config = load_json(config_file)
    hysteria_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "HYSTERIA"),
        None,
    )
    if hysteria_inbound is None:
        raise ValueError('No inbound with tag "HYSTERIA" found in the configuration.')

    obfs = hysteria_inbound.setdefault("obfs", {})
    tls = hysteria_inbound.setdefault("tls", {})

    obfs["password"] = proxy_config["OBFS"]
    tls["server_name"] = proxy_config["SNI"]
    hysteria_inbound["masquerade"] = f"https://{proxy_config['SNI']}"

    save_json(config, config_file)


def hysteria_add_user(user_info: dict, config_file: str):
    config = load_json(config_file)
    hysteria_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "HYSTERIA"),
        None,
    )
    if hysteria_inbound is None:
        raise ValueError('No inbound with tag "HYSTERIA" found in the configuration.')

    hysteria_inbound.setdefault("users", [])

    new_user = {"name": user_info["name"], "password": user_info["password"]}

    hysteria_inbound["users"].append(new_user)
    save_json(config, config_file)


def hysteria_remove_user(username: str, config_file: str):
    config = load_json(config_file)
    hysteria_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "HYSTERIA"),
        None,
    )
    if hysteria_inbound is None:
        raise ValueError('No inbound with tag "HYSTERIA" found in the configuration.')

    users = hysteria_inbound.get("users", [])

    user_to_remove = next((c for c in users if c.get("name") == username), None)
    if user_to_remove:
        users.remove(user_to_remove)

    save_json(config, config_file)


def get_hysteria_share_uri(username: str, config_file: str) -> str:
    from base.config import PUBLIC_IP

    config = load_json(config_file)
    hysteria_inbound = next(
        (inb for inb in config.get("inbounds", []) if inb.get("tag") == "HYSTERIA"),
        None,
    )
    if hysteria_inbound is None:
        raise ValueError('No inbound with tag "HYSTERIA" found in the configuration.')

    users = hysteria_inbound.get("users", [])
    obfs = hysteria_inbound.get("obfs", {})
    tls = hysteria_inbound.get("tls", {})

    user_info = next((c for c in users if c.get("name") == username), None)
    if user_info:
        return f"hysteria2://{user_info['password']}@{PUBLIC_IP}:8443/?insecure=1&obfs=salamander&obfs-password={obfs['password']}&sni={tls['server_name']}#{user_info['name']}%20[Hysteria]"
    else:
        raise ValueError(f'User "{username}" not found in the configuration.')


def prompt_hysteria_sni() -> str:
    """
    Keep asking the user for a value until it matches
    the ``DOMAIN.TLD`` pattern.
    """
    while True:
        proxy_sni = input("\nEnter a SNI for Hysteria: ")
        if is_domain(proxy_sni) or is_subdomain(proxy_sni):
            print(f"✅  Accepted → domain={proxy_sni}")
            return proxy_sni
        else:
            print("❌  Invalid format.  Expected ``DOMAIN.TLD``")
            continue

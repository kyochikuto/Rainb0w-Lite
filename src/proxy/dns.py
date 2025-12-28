from rich import print

from utils.helper import (
    load_json,
    save_json,
)


def change_dns_server(dns_tag: str, config_file_path: str):
    config = load_json(config_file_path)
    if "dns" in config:
        dns_config = config["dns"]
        if "final" in dns_config:
            dns_config["final"] = dns_tag

    save_json(config, config_file_path)


def enable_porn_dns_blocking(config_file_path: str):
    print("[bold green]>> Enabling AdGuard Family Protection DNS")
    change_dns_server("adguard-dns-family", config_file_path)


def disable_porn_dns_blocking(config_file_path: str):
    print("[bold green]>> Disabling AdGuard Family Protection DNS (Only block ads)")
    change_dns_server("adguard-dns", config_file_path)


def revert_to_local_dns(config_file_path: str):
    print("[bold green]>> Reverting to local DNS servers")
    change_dns_server("local-dns", config_file_path)

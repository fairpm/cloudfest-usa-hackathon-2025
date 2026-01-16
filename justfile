
default:
    @just --list

[arg("no_hook", long="no-hook", value="NO_INSTALL_HOOK=1", help="Skip auto-installation of signoff hook")]
checkout repo no_hook="":
    {{no_hook}} meta/bin/checkout-fair-project {{repo}}


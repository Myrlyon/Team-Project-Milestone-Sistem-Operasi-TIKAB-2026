#!/usr/bin/env bash
# Use -E so the ERR trap also fires inside functions
set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
cd "$SCRIPT_DIR"

log_info() { echo "[INFO] $*"; }
log_ok()
{ echo "[SUCCESS] $*"; }
log_err() { echo "[ERROR] $*" >&2; }

error_handler() {
    local line_no=$1 last_command=$2
    log_err "Command '${last_command}' failed at line ${line_no}!"
    exit 1
}
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap 'echo "[INFO] Script cancelled by user."; exit 130' INT TERM
preflight_checks() {
    [[ -f /etc/os-release ]] || { log_err "Unknown OS"; exit 1; }
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    log_err "Run as root or configure passwordless sudo"; exit 1
    fi
    local f
    for f in .env app/app.py systemd/webapp.service \
    configs/nginx.conf.template configs/database.cnf; do
    [[ -f "$f" ]] || { log_err "Missing file: $f"; exit 1; }
    done
}

main() {
    preflight_checks
    # shellcheck source=/dev/null
    source scripts/01_setup_users.sh
    source scripts/02_install_deps.sh
    source scripts/03_configure_sec.sh
    source scripts/04_deploy_services.sh
    load_env
    setup_users
    install_deps
    setup_database
    configure_security
    deploy_app
    render_nginx_config
    install_systemd_unit
    bash tests/health_check.sh
    log_ok "Deployment finished."
}
main "$@"
load_env() {
    local env_file="${SCRIPT_DIR:-$(pwd)}/.env"
    if [[ ! -f "$env_file" ]]; then
        echo "[ERROR] .env not found. Copy env.example to .env first." >&2
        exit 1
    fi
    chmod 0600 "$env_file"
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
    : "${DB_NAME:?DB_NAME must be defined}"
    : "${DB_USER:?DB_USER must be defined}"
    : "${DB_PASS:?DB_PASS must be defined}"
    export APP_PORT="${APP_PORT:-8000}" DOMAIN_NAME="${DOMAIN_NAME:-_}"
}

setup_users() {
    getent group webapp >/dev/null || sudo groupadd -r webapp
    if ! id -u webapp >/dev/null 2>&1; then
        sudo useradd -r -g webapp -s /sbin/nologin -d /var/www/webapp \
        -m -c "Web Application Daemon" webapp
        log_ok "User webapp created."
    else
        log_info "User webapp already exists."
    fi

    # install -d creates AND sets owner/mode, so it is naturally idempotent
    sudo install -d -o webapp -g webapp -m 0750 \
    /var/www/webapp /var/www/webapp/data /var/log/webapp

    # Secrets for the service: root-owned, readable by group webapp only
    sudo install -d -o root -g webapp -m 0750 /etc/webapp
    sudo install -o root -g webapp -m 0640 "${SCRIPT_DIR}/.env"
    /etc/webapp/webapp.env
}

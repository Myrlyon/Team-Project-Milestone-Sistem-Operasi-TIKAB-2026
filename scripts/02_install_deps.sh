install_deps() {
    local os_id
    os_id="$(. /etc/os-release && echo "$ID")"
    case "$os_id" in
        rhel|rocky|almalinux|fedora)
            sudo dnf install -y nginx mariadb-server python3 gettext curl
            MARIADB_CONF_DIR=/etc/my.cnf.d ;;
        ubuntu|debian)
            # 'sudo env ...' because sudo resets the environment and would drop
            # a plain 'export DEBIAN_FRONTEND=...'
            sudo env DEBIAN_FRONTEND=noninteractive apt-get update -y
            sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
            nginx mariadb-server python3 gettext-base curl
            MARIADB_CONF_DIR=/etc/mysql/mariadb.conf.d ;;
        *) echo "[ERROR] Distro $os_id is not supported!" >&2; exit 1 ;;
    esac
    export MARIADB_CONF_DIR
}

setup_database() {
    local src="${SCRIPT_DIR}/configs/database.cnf"
    local dst="${MARIADB_CONF_DIR}/99-hardening.cnf"
    sudo systemctl enable --now mariadb
    if ! sudo cmp -s "$src" "$dst"; then
        sudo install -m 0644 "$src" "$dst"
        sudo systemctl restart mariadb
    fi

    sudo mariadb <<SQL
    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4;
    CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY
    '${DB_PASS}';
    ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
    FLUSH PRIVILEGES;
    SQL
}

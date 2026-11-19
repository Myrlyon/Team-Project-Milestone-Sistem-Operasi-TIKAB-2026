configure_security() {
    local os_id
    os_id="$(. /etc/os-release && echo "$ID")"
    case "$os_id" in
        ubuntu|debian)
            sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ufw
            sudo ufw allow 22/tcp      # allow SSH FIRST so you are not locked out
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            sudo ufw --force enable ;;
        rhel|rocky|almalinux|fedora)
            sudo dnf install -y firewalld
            sudo systemctl enable --now firewalld
            sudo firewall-cmd --permanent --add-service=ssh
            sudo firewall-cmd --permanent --add-service=http
            sudo firewall-cmd --permanent --add-service=https
            sudo firewall-cmd --reload

            if command -v getenforce >/dev/null && [[ "$(getenforce)" != "Disabled" 
]]; then
            sudo setsebool -P httpd_can_network_connect 1   # lets Nginx reach 
:8000
            fi ;;
        *) log_err "Distro $os_id is not supported!"; exit 1 ;;
    esac
    # Port 3306 is intentionally NOT opened: the database stays internal.
}
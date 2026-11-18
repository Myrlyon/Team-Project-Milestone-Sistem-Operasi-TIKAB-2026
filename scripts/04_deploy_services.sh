deploy_app() {
    sudo install -o webapp -g webapp -m 0640 \
        "${SCRIPT_DIR}/app/app.py" /var/www/webapp/app.py
}
render_nginx_config() {
    local tmp; tmp="$(mktemp)"
    # Single quotes are REQUIRED: only these two variables are substituted,
    # so nginx's own $host, $remote_addr, etc. stay untouched.
    envsubst '${APP_PORT} ${DOMAIN_NAME}' \
        < "${SCRIPT_DIR}/configs/nginx.conf.template" > "$tmp"

    sudo rm -f /etc/nginx/sites-enabled/default
    # Debian/Ubuntu default site
    if ! sudo cmp -s "$tmp" /etc/nginx/conf.d/webapp.conf; then
        sudo install -m 0644 "$tmp" /etc/nginx/conf.d/webapp.conf
    fi
    rm -f "$tmp"
    sudo nginx -t
    sudo systemctl enable --now nginx
    sudo systemctl reload nginx
}
install_systemd_unit() {
    local changed=0
    if ! sudo cmp -s "${SCRIPT_DIR}/systemd/webapp.service" \
                /etc/systemd/system/webapp.service; then
        sudo install -m 0644 "${SCRIPT_DIR}/systemd/webapp.service" \
            /etc/systemd/system/webapp.service
        sudo systemctl daemon-reload
        changed=1
    fi
    sudo systemctl enable --now webapp.service
    if [[ $changed -eq 1 ]]; then sudo systemctl restart webapp.service; fi
}
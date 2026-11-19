#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0

check() {
    local name=$1
    shift
    if "$@" >/dev/null 2>&1; then
        echo "[PASS] $name"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name"
        FAIL=$((FAIL + 1))
    fi
}

db_not_public() {
    ! ss -tln | grep -Eq '(0\.0\.0\.0|\*|\[::\]):3306'
}

runs_as_webapp() {
    local pid
    pid="$(systemctl show -p MainPID --value webapp.service)"
    [[ "$(ps -o user= -p "$pid" | tr -d ' ')" == "webapp" ]]
}

load_test() {
    local i
    for i in $(seq 1 50); do
        curl -fsS --max-time 5 http://127.0.0.1/health >/dev/null || return 1
    done
}

check "nginx active" systemctl is-active --quiet nginx
check "mariadb active" systemctl is-active --quiet mariadb
check "webapp active" systemctl is-active --quiet webapp
check "HTTP /health via nginx" curl -fsS --max-time 5 http://127.0.0.1/health
check "DB not publicly bound" db_not_public
check "app runs as webapp" runs_as_webapp
check "webapp has no shell" bash -c "getent passwd webapp | grep -q nologin"
check "50 requests succeed" load_test

echo "Result: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]]
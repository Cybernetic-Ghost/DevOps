#!/bin/bash
# pf.sh — портфорвард Prometheus и Grafana с авто-подбором свободных портов

set -euo pipefail

NAMESPACE="ff-play"

PROM_SVC="monitoring-kube-prometheus-prometheus"
PROM_REMOTE=9090       # порт сервиса Prometheus в k8s
PROM_PREF=9090         # желаемый локальный порт

GRAF_SVC="monitoring-grafana"
GRAF_REMOTE=80         # порт сервиса Grafana в k8s
GRAF_PREF=3000         # желаемый локальный порт

LOG_PROM="/tmp/pf-prom.log"
LOG_GRAF="/tmp/pf-grafana.log"

is_free() { # 0 = свободен, 1 = занят
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ! ss -ltn "( sport = :$p )" 2>/dev/null | tail -n +2 | grep -q .
  else
    ! lsof -iTCP:$p -sTCP:LISTEN -nP >/dev/null 2>&1
  fi
}

find_free_port() { # find_free_port <start_port> [tries]
  local start_port="${1:-1024}"
  local tries="${2:-50}"
  local p="$start_port"
  for _ in $(seq 1 "$tries"); do
    if is_free "$p"; then echo "$p"; return 0; fi
    p=$((p+1))
  done
  echo "Нет свободного порта начиная с $start_port (попыток: $tries)" >&2
  return 1
}

cleanup() {
  echo -e "\n[INFO] Останавливаю портфорварды..."
  pkill -P $$ || true
  exit 0
}
trap cleanup SIGINT SIGTERM

PROM_LOCAL=$(find_free_port "$PROM_PREF" 100)
GRAF_LOCAL=$(find_free_port "$GRAF_PREF" 100)

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[ -z "${IP:-}" ] && IP="127.0.0.1"

echo "[INFO] Выбранные локальные порты:"
echo "  Prometheus: ${PROM_LOCAL}  (remote ${PROM_REMOTE})"
echo "  Grafana   : ${GRAF_LOCAL}  (remote ${GRAF_REMOTE})"
echo "[INFO] Логи: $LOG_PROM , $LOG_GRAF"

echo "[INFO] Запускаю портфорвард Prometheus: 0.0.0.0:${PROM_LOCAL} -> svc/${PROM_SVC}:${PROM_REMOTE}"
kubectl -n "$NAMESPACE" port-forward "svc/${PROM_SVC}" \
  --address 0.0.0.0 "${PROM_LOCAL}:${PROM_REMOTE}" >"$LOG_PROM" 2>&1 &

sleep 0.5

echo "[INFO] Запускаю портфорвард Grafana: 0.0.0.0:${GRAF_LOCAL} -> svc/${GRAF_SVC}:${GRAF_REMOTE}"
kubectl -n "$NAMESPACE" port-forward "svc/${GRAF_SVC}" \
  --address 0.0.0.0 "${GRAF_LOCAL}:${GRAF_REMOTE}" >"$LOG_GRAF" 2>&1 &

echo "[INFO] Готово. Доступ с твоей машины:"
echo "  Prometheus → http://${IP}:${PROM_LOCAL}"
echo "  Grafana    → http://${IP}:${GRAF_LOCAL}"
echo "[INFO] Ctrl+C — остановить. Смотреть логи: tail -f $LOG_PROM $LOG_GRAF"

wait


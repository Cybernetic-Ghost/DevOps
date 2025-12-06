#!/bin/sh
set -e

# Создание директорий для логов
mkdir -p /var/log/modsecurity
chown nginx:nginx /var/log/modsecurity

# Запуск inotify для отслеживания изменений конфига
(
  while true; do
    inotifywait -e modify,move,create,delete /etc/nginx/modsecurity/modsecurity.conf
    echo "$(date) - Config changed, reloading Nginx..."
    nginx -s reload
  done
) &

# Старт Nginx
exec nginx -g "daemon off;"
FROM nginx:1.25-alpine

# Установка ModSecurity
RUN apk add --no-cache \
    modsecurity \
    modsecurity-nginx \
    inotify-tools \
    curl

# Копирование конфигов
COPY modsecurity.conf /etc/nginx/modsecurity/modsecurity.conf
COPY entrypoint.sh /entrypoint.sh

RUN mkdir -p /etc/nginx/modsecurity && \
    chmod +x /entrypoint.sh && \
    chown -R nginx:nginx /etc/nginx/modsecurity

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
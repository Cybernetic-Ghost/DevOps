#!/bin/bash
set -e

GO_VERSION=1.23.0

echo "Скачиваю Go ${GO_VERSION}..."
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

echo "Удаляю старую установку Go..."
sudo rm -rf /usr/local/go

echo "Распаковываю Go..."
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

echo "Добавляю Go в PATH..."
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi

echo "Готово! Перезагрузи сессию или выполни: source ~/.bashrc"


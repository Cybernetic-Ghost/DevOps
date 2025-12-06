#!/usr/bin/env bash
# Установка Go 1.23.0 и удаление старых версий
set -euo pipefail

GO_VERSION="1.23.0"

# Определяем архитектуру для архива
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GO_ARCH="amd64" ;;
  aarch64|arm64) GO_ARCH="arm64" ;;
  *)
    echo "Неподдерживаемая архитектура: $ARCH"
    exit 1
    ;;
esac

TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
URL="https://go.dev/dl/${TARBALL}"

# Нужен ли sudo
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "==> Удаляю возможные пакеты golang из apt (если были установлены)..."
$SUDO apt-get update -y >/dev/null 2>&1 || true
$SUDO apt-get purge -y 'golang*' >/dev/null 2>&1 || true
$SUDO apt-get autoremove -y >/dev/null 2>&1 || true

echo "==> Удаляю старую установку /usr/local/go (если есть)..."
$SUDO rm -rf /usr/local/go

echo "==> Скачиваю Go ${GO_VERSION} (${GO_ARCH})..."
cd /tmp
rm -f "${TARBALL}"
curl -fsSL "${URL}" -o "${TARBALL}"

# Если хочешь проверять checksum — раскомментируй 3 строки ниже:
# echo "==> (опционально) Проверка SHA256..."
# curl -fsSL "${URL}.sha256" -o "${TARBALL}.sha256"
# sha256sum -c "${TARBALL}.sha256"

echo "==> Распаковываю в /usr/local ..."
$SUDO tar -C /usr/local -xzf "${TARBALL}"

echo "==> Прописываю PATH системно (/etc/profile.d/go.sh)..."
GO_PROFILE='/etc/profile.d/go.sh'
TMP_GO_PROFILE="$(mktemp)"
cat > "${TMP_GO_PROFILE}" <<'EOF'
# Go toolchain
export GOROOT=/usr/local/go
export GOPATH="${HOME}/go"
export PATH="$PATH:/usr/local/go/bin:${HOME}/go/bin"
EOF
$SUDO mv "${TMP_GO_PROFILE}" "${GO_PROFILE}"
$SUDO chmod 0644 "${GO_PROFILE}"

# На всякий случай пропишем и в ~/.bashrc для текущего пользователя
if ! grep -q '/usr/local/go/bin' "${HOME}/.bashrc" 2>/dev/null; then
  echo 'export GOROOT=/usr/local/go' >> "${HOME}/.bashrc"
  echo 'export GOPATH="${HOME}/go"' >> "${HOME}/.bashrc"
  echo 'export PATH="$PATH:/usr/local/go/bin:${HOME}/go/bin"' >> "${HOME}/.bashrc"
fi

echo "==> Включаю auto-toolchain (подтягивать нужный Go при сборке, если требуется)..."
if ! grep -q 'GOTOOLCHAIN=' "${HOME}/.bashrc" 2>/dev/null; then
  echo 'export GOTOOLCHAIN=auto' >> "${HOME}/.bashrc"
fi

echo "==> Готово. Перезапусти shell или выполни: source /etc/profile.d/go.sh && source ~/.bashrc"
echo "==> Проверка версии:"
# Загрузим переменные в текущую сессию, если возможно
source /etc/profile.d/go.sh || true
source "${HOME}/.bashrc" || true
go version || { echo "Открой новую сессию терминала и снова проверь 'go version'."; exit 0; }


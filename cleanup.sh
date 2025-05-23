#!/bin/bash
set -e

echo "========== 🧼 Базовая очистка системы (безопасно) =========="

echo "1️⃣ 🗑 Очистка кеша пакетов apt..."
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y

echo "2️⃣ 📦 Очистка snap кэша..."
sudo rm -rf /var/cache/snapd/

echo "3️⃣ 📂 Очистка пользовательского кэша..."
rm -rf ~/.cache/*
rm -rf ~/.cache/thumbnails/*
sudo rm -rf /root/.cache/*

echo "4️⃣ 📚 Очистка логов systemd (journal)..."
sudo journalctl --rotate
sudo journalctl --vacuum-time=3d
sudo journalctl --vacuum-size=200M

echo "========== 🐳 Очистка Docker =========="

echo "5️⃣ ⛔ Остановка и удаление неиспользуемых контейнеров, образов, сетей..."
docker container prune -f
docker image prune -a -f
docker volume prune -f
docker network prune -f
docker system prune -a --volumes -f

echo "6️⃣ 🗂 Ограничение логов Docker (если ещё не настроено)..."
DOCKER_CONF="/etc/docker/daemon.json"
if [ ! -f "$DOCKER_CONF" ]; then
  echo "{}" | sudo tee "$DOCKER_CONF"
fi

if ! grep -q "max-size" "$DOCKER_CONF"; then
  sudo tee "$DOCKER_CONF" > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

echo "========== 📁 Очистка логов =========="

echo "7️⃣ 📉 Очистка старых и сжатых логов в /var/log..."
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
sudo find /var/log -type f -name "*.log" -size +10M -exec truncate -s 0 {} \;

echo "========== 📊 Топ-10 папок по размеру (для анализа) =========="
sudo du -sh /* 2>/dev/null | sort -hr | head -n 10

echo "✅ Очистка завершена!"

#!/bin/bash

# Функция для установки недостающих пакетов
install_packages() {
    PACKAGES=("curl" "dnsutils" "mtr")

    for PACKAGE in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -qw $PACKAGE; then
            echo "Установка пакета $PACKAGE..."
            sudo apt-get install -y $PACKAGE
        else
            echo "Пакет $PACKAGE уже установлен."
        fi
    done
}

# Удаление старого и установка нового Speedtest CLI
echo "Удаление старого Speedtest CLI и установка нового..."
if [ -f /etc/apt/sources.list.d/speedtest.list ]; then
    sudo rm /etc/apt/sources.list.d/speedtest.list
fi
sudo apt-get update
sudo apt-get remove -y speedtest speedtest-cli

# Установка нового Speedtest CLI
sudo apt-get install -y curl
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install -y speedtest

# Установка недостающих пакетов
install_packages

# Проверка скорости интернета
echo "Проверка скорости интернета..."
speedtest

# Проверка доступности DNS серверов
DNS_SERVERS=("8.8.8.8" "8.8.4.4" "1.1.1.1")

for DNS_SERVER in "${DNS_SERVERS[@]}"; do
    echo "Проверка доступности DNS сервера $DNS_SERVER..."
    dig @$DNS_SERVER google.com +short
    if [ $? -eq 0 ]; then
        echo "DNS сервер $DNS_SERVER доступен."
    else
        echo "DNS сервер $DNS_SERVER недоступен."
    fi
done

# Проверка качества соединения до нескольких локаций
LOCATIONS=("google.com" "cloudflare.com" "yandex.ru")

for LOCATION in "${LOCATIONS[@]}"; do
    echo "Проверка качества соединения до $LOCATION..."
    mtr -r -c 10 $LOCATION
done

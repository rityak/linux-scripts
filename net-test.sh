#!/bin/bash

# Функция для установки недостающих пакетов
install_packages() {
    PACKAGES=("curl" "dnsutils" "mtr" "net-tools" "jq")

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

# Функция для красивого вывода разделителя
print_separator() {
    echo "============================================================"
}

# Проверка MTU
echo "Проверка MTU..."
MTU=$(ip link show | grep mtu | awk '{print $5}')
echo "MTU: $MTU"

# Проверка IP адресов
echo "Проверка IP адресов..."
IP_ADDRESSES=$(hostname -I)
echo "IP адреса: $IP_ADDRESSES"

# Проверка скорости интернета
print_separator
echo "Проверка скорости интернета..."
SPEEDTEST_OUTPUT=$(speedtest --format=json)

DOWNLOAD_SPEED=$(echo $SPEEDTEST_OUTPUT | jq '.download.bandwidth' | awk '{print $1/125000 " Mbps"}')
UPLOAD_SPEED=$(echo $SPEEDTEST_OUTPUT | jq '.upload.bandwidth' | awk '{print $1/125000 " Mbps"}')
PING=$(echo $SPEEDTEST_OUTPUT | jq '.ping.latency' | awk '{print $1 " ms"}')

# Проверка доступности DNS серверов
print_separator
echo "Проверка доступности DNS серверов..."
DNS_SERVERS=("8.8.8.8" "8.8.4.4" "1.1.1.1")
DNS_RESULTS=()

for DNS_SERVER in "${DNS_SERVERS[@]}"; do
    dig @$DNS_SERVER google.com +short > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        DNS_RESULTS+=("DNS сервер $DNS_SERVER доступен.")
    else
        DNS_RESULTS+=("DNS сервер $DNS_SERVER недоступен.")
    fi
done

# Проверка качества соединения до нескольких локаций
print_separator
echo "Проверка качества соединения до нескольких локаций..."
LOCATIONS=("google.com" "cloudflare.com" "yandex.ru")
MTR_RESULTS=()

for LOCATION in "${LOCATIONS[@]}"; do
    MTR_RESULT=$(mtr -r -c 10 $LOCATION)
    MTR_RESULTS+=("$MTR_RESULT")
done

# Проверка доступности популярных сервисов
check_service_availability() {
    SERVICE=$1
    HOST=$2
    nc -z -v -w5 $HOST 80 &> /dev/null
    if [ $? -eq 0 ]; then
        echo "$SERVICE доступен."
    else
        echo "$SERVICE недоступен."
    fi
}

SERVICES=(
    "Google:google.com"
    "Facebook:facebook.com"
    "YouTube:youtube.com"
    "Amazon:amazon.com"
    "Netflix:netflix.com"
)

SERVICE_RESULTS=()

for SERVICE in "${SERVICES[@]}"; do
    NAME=$(echo $SERVICE | cut -d':' -f1)
    HOST=$(echo $SERVICE | cut -d':' -f2)
    RESULT=$(check_service_availability $NAME $HOST)
    SERVICE_RESULTS+=("$RESULT")
done

# Вывод резюме
print_separator
echo "Резюме диагностики сети"
print_separator
echo "1. MTU: $MTU"
echo "2. IP адреса: $IP_ADDRESSES"
echo "3. Скорость интернета:"
echo "   Download: $DOWNLOAD_SPEED"
echo "   Upload: $UPLOAD_SPEED"
echo "   Ping: $PING"
print_separator
echo "4. Доступность DNS серверов:"
for RESULT in "${DNS_RESULTS[@]}"; do
    echo "   $RESULT"
done
print_separator
echo "5. Качество соединения до локаций:"
for RESULT in "${MTR_RESULTS[@]}"; do
    echo "$RESULT"
    print_separator
done
echo "6. Доступность популярных сервисов:"
for RESULT in "${SERVICE_RESULTS[@]}"; do
    echo "   $RESULT"
done
print_separator

# Дополнительные тесты и полезная информация

# Проверка настроек DNS
echo "Проверка настроек DNS..."
DNS_CONFIG=$(cat /etc/resolv.conf)
echo "Настройки DNS:"
echo "$DNS_CONFIG"
print_separator

# Проверка сетевой статистики
echo "Проверка сетевой статистики..."
NETSTAT_OUTPUT=$(netstat -i)
echo "Сетевая статистика:"
echo "$NETSTAT_OUTPUT"
print_separator

# Проверка таблицы маршрутизации
echo "Проверка таблицы маршрутизации..."
ROUTE_OUTPUT=$(ip route)
echo "Таблица маршрутизации:"
echo "$ROUTE_OUTPUT"
print_separator

# Проверка сетевых подключений
echo "Проверка сетевых подключений..."
SS_OUTPUT=$(ss -tuln)
echo "Сетевые подключения:"
echo "$SS_OUTPUT"
print_separator

echo "Диагностика завершена."

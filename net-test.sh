#!/bin/bash

# Функция для установки недостающих пакетов
install_packages() {
    PACKAGES=("curl" "dnsutils" "mtr" "net-tools")

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
SPEEDTEST_OUTPUT=$(speedtest)

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

# Вывод резюме
print_separator
echo "Резюме диагностики сети"
print_separator
echo "1. MTU: $MTU"
echo "2. IP адреса: $IP_ADDRESSES"
echo "3. Скорость интернета:"
echo "$SPEEDTEST_OUTPUT"
echo "4. Доступность DNS серверов:"
for RESULT in "${DNS_RESULTS[@]}"; do
    echo "$RESULT"
done
echo "5. Качество соединения до локаций:"
for RESULT in "${MTR_RESULTS[@]}"; do
    echo "$RESULT"
    print_separator
done

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


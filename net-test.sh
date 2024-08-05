#!/bin/bash

LOG_FILE="network_test_log.txt"

# Функция для логирования сообщений
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Удаление старого speedtest и всех его репозиториев
log "Удаление старого speedtest и всех его репозиториев..."
sudo rm /etc/apt/sources.list.d/speedtest.list
sudo apt-get update
sudo apt-get remove -y speedtest speedtest-cli
log "Удаление завершено."

# Установка необходимых инструментов
log "Установка curl..."
sudo apt-get install -y curl
log "Установка curl завершена."

# Установка нового speedtest
log "Установка нового speedtest..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install -y speedtest
log "Установка speedtest завершена."

# Запуск теста без аргументов и запись результата в файл
log "Запуск speedtest без аргументов..."
speedtest | tee speedtest_default.txt | tee -a $LOG_FILE
log "Тест без аргументов завершен. Результат сохранен в speedtest_default.txt."

# Список серверов для тестирования
servers=(62942 48192 62943 62945)

# Запуск тестов для каждого сервера и запись результатов в файлы
for server in "${servers[@]}"; do
    log "Запуск speedtest для сервера $server..."
    speedtest -s $server | tee speedtest_server_$server.txt | tee -a $LOG_FILE
    log "Тест для сервера $server завершен. Результат сохранен в speedtest_server_$server.txt."
done

# Выполнение трассировки до DNS серверов
dns_servers=("1.1.1.1" "8.8.8.8")

for dns in "${dns_servers[@]}"; do
    log "Запуск трассировки до DNS сервера $dns..."
    traceroute $dns | tee traceroute_$dns.txt | tee -a $LOG_FILE
    log "Трассировка до DNS сервера $dns завершена. Результат сохранен в traceroute_$dns.txt."
done

log "Все тесты завершены. Результаты сохранены в соответствующих файлах."

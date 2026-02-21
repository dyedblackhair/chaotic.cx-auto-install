#!/bin/bash

#логи
LOG_FILE="/tmp/chaotic-install-$(date +%Y%m%d-%H%M%S).log"
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_cmd() {
  log "Выполнение: $1"
  eval "$1" >>"$LOG_FILE" 2>&1
  local status=$?
  if [ $status -ne 0 ]; then
    log "ОШИБКА: Команда завершилась с кодом $status"
    return $status
  fi
  log "УСПЕШНО: Команда выполнена"
  return 0
}

# проверка судо
if [ "$EUID" -ne 0 ]; then
  log "Этот скрипт должен быть запущен с правами root"
  echo "Пожалуйста, запустите с sudo: sudo $0"
  exit 1
fi

log "=== НАЧАЛО УСТАНОВКИ CHAOTIC-AUR ==="
log "Лог-файл: $LOG_FILE"

# Шаг 1: Получение первичного ключа
log "Шаг 1: Получение первичного ключа"
run_cmd "pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com"
if [ $? -ne 0 ]; then
  log "Не удалось получить ключ, пробуем альтернативный keyserver..."
  run_cmd "pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keyserver.ubuntu.com:80"
fi

# Шаг 2: Подписание ключа
log "Шаг 2: Подписание ключа"
run_cmd "pacman-key --lsign-key 3056513887B78AEB"

# Шаг 3: Установка chaotic-keyring
log "Шаг 3: Установка chaotic-keyring"
run_cmd "pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'"

# Шаг 4: Установка chaotic-mirrorlist
log "Шаг 4: Установка chaotic-mirrorlist"
run_cmd "pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'"

# Шаг 5: Добавление репозитория в pacman.conf
log "Шаг 5: Добавление репозитория в pacman.conf"

# Проверяем, есть ли уже запись о chaotic-aur
if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
  log "Репозиторий chaotic-aur уже существует в pacman.conf"
else
  # Добавляем репозиторий в конец файла
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf
  log "Репозиторий добавлен в pacman.conf"
fi

# Шаг 6: Обновление системы
log "Шаг 6: Обновление системы с новым репозиторием"
run_cmd "pacman -Syu --noconfirm"

# Проверка установки
log "Шаг 7: Проверка установки"
if run_cmd "pacman -Si chaotic-aur/chaotic-keyring > /dev/null 2>&1"; then
  log "✓ Chaotic-AUR успешно установлен и настроен!"
  log "✓ Репозиторий готов к использованию"
  log "✓ Пример установки пакета: sudo pacman -S firedragon"
else
  log "✗ Ошибка: Chaotic-AUR не настроен правильно"
  exit 1
fi

log "=== УСТАНОВКА ЗАВЕРШЕНА ==="
log "Лог-файл сохранен: $LOG_FILE"
echo ""
echo "✅ Chaotic-AUR успешно установлен!"
echo "📝 Лог-файл: $LOG_FILE"
echo "🚀 Теперь вы можете устанавливать пакеты: sudo pacman -S firedragon"

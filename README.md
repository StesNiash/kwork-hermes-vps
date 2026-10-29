# kwork-hermes-vps

Установщик и рабочая обвязка для [Hermes Agent](https://github.com/NousResearch/hermes-agent) на Ubuntu VPS.
Задача репозитория — превратить «поставь агента» в воспроизводимый деплой с проверкой, логами, backup и откатом.

## Что входит

- Docker Compose с официальным образом `nousresearch/hermes-agent`.
- Telegram-шлюз и dashboard на `127.0.0.1`.
- Генерация `.env`, API-ключа dashboard и ключа OpenAI-совместимого API.
- Healthcheck и `scripts/smoke.sh`.
- Backup / restore / update / uninstall.
- Опциональный HTTPS через Caddy (`--profile proxy`).
- Честный список ограничений и чек-лист приёмки.

## Требования

| Параметр | Значение |
|---|---|
| ОС | Ubuntu 22.04 / 24.04 (Debian 12 — предупреждение, но работает) |
| RAM | 2 GB минимум, 4 GB комфортно |
| Диск | 10 GB свободно |
| Доступ | root или sudo |
| Внешнее | Telegram bot token, ключ модели (OpenRouter / Anthropic / OpenAI) |
| Сеть | исходящий HTTPS до `api.telegram.org:443` |

Hermes работает в Docker. Docker и compose plugin не ставятся молча: используйте `--with-docker` или установите заранее.

Перед установкой проверьте Telegram:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' --max-time 10 https://api.telegram.org/
```

`200` или `404` — сеть в порядке. `000` — хостинг режет Telegram; нужен VPS вне РФ или разрешённый прокси. На Cloud.ru 29.10.2026 соединение стабильно уходило в timeout.

## Быстрый старт

```bash
git clone https://github.com/StesNiash/kwork-hermes-vps.git
cd kwork-hermes-vps
sudo bash install.sh --with-docker
```

Скрипт:

1. Проверяет ОС и базовые пакеты.
2. Копирует стек в `/opt/hermes-stack`.
3. Создаёт `.env` с правами `600`.
4. Спрашивает Telegram token и (опционально) OpenRouter key.
5. Генерирует пароль dashboard и API-ключ.
6. Поднимает контейнер и ждёт `healthy`.
7. Запускает smoke-check.

Пароль dashboard печатается один раз в конце. Сохраните его в менеджере паролей.

### Неинтерактивный режим

```bash
sudo TELEGRAM_BOT_TOKEN='123456:ABC...' \
     OPENROUTER_API_KEY='sk-or-...' \
     bash install.sh --non-interactive --with-docker
```

Если `.env` уже есть, значения из него используются повторно.

## Доступ

Dashboard слушает только localhost:

```bash
ssh -L 9119:127.0.0.1:9119 root@<vps-ip>
# открыть http://127.0.0.1:9119
```

Telegram: напишите боту, затем при необходимости подтвердите pairing:

```bash
docker compose exec -T hermes hermes pairing list
docker compose exec -T hermes hermes pairing approve <id>
```

OpenAI-совместимый API:

```bash
curl -H "Authorization: Bearer $(grep '^API_SERVER_KEY=' .env | cut -d= -f2-)" \
     http://127.0.0.1:8642/health
```

Порт `8642` опубликован только на localhost. Не открывайте его в интернет без отдельной авторизации и reverse proxy.

## HTTPS через Caddy

1. Направьте A-запись домена на IP VPS.
2. В `.env` заполните `DOMAIN` и `LETSENCRYPT_EMAIL`.
3. Запустите:

```bash
sudo docker compose --profile proxy up -d
```

Caddy получит сертификат и проксирует dashboard на `hermes:9119`.
Dashboard всё равно требует basic auth: без `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` он не поднимется на внешнем интерфейсе.

## AWS

Пошаговая инструкция для тестового EC2/Lightsail: [docs/AWS.md](docs/AWS.md).

## Обслуживание

```bash
./scripts/healthcheck.sh      # статус контейнера
./scripts/logs.sh             # логи gateway
./scripts/smoke.sh            # проверка конфигурации и здоровья
./scripts/backup.sh           # архив ./data в ./backups
./scripts/restore.sh backups/hermes-data-YYYYMMDD-HHMMSS.tar.gz
./scripts/update.sh           # pull + recreate + smoke
./scripts/uninstall.sh        # остановить, данные сохранить
./scripts/uninstall.sh --purge  # удалить всё (с подтверждением DELETE)
```

Backup останавливает контейнер на время копирования `./data`, затем поднимает его обратно.

## Проверка репозитория

```bash
bash tests/run.sh
```

Проверяются shell-синтаксис, наличие обязательных файлов и `docker compose config`.
Live-проверка на чистом VPS — отдельный обязательный шаг перед сдачей клиенту; в этом окружении она не выполнялась.

## Ограничения

- Это не «установка за 30 секунд»: Docker, загрузка образа и первичная настройка занимают время.
- Hermes не обходит лимиты модели и не оплачивает API за клиента.
- Dashboard и API не предназначены для публикации без TLS и авторизации.
- Обновление образа может изменить схему конфигурации; backup делайте до `update.sh`.
- При `docker compose down -v` данные не удаляются (volume здесь bind-mount), но `--purge` удаляет каталог.
- Официальный образ не поддерживает `hermes update`; обновление — новый image + recreate.
- Telegram Bot API может быть недоступен с конкретного хостинга. Это проверяется до установки, а не после.

## Источники

- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
- [Installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation)
- [Docker setup](https://hermes-agent.nousresearch.com/docs/user-guide/docker)
- [Messaging gateway](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/)

## Лицензия

MIT. Hermes Agent — MIT, Nous Research.

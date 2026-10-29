# Архитектура kwork-hermes-vps

## Схема

```text
Ubuntu VPS
└── Docker Compose
    ├── hermes  (nousresearch/hermes-agent)
    │   ├── /opt/data  ← bind mount ./data
    │   ├── :8642      ← OpenAI-compatible API (localhost)
    │   └── :9119      ← dashboard (localhost)
    └── caddy (profile: proxy)
        ├── :80/:443
        └── reverse_proxy hermes:9119
```

## Почему Docker

- Официальный образ поддерживается Nous Research.
- Данные лежат в одном каталоге `./data`, его просто бэкапить.
- Обновление — pull нового образа и recreate, а не `pip install` на хосте.
- Откат — вернуть предыдущий тег или backup.

## Границы

- Контейнер не публикует dashboard и API в интернет.
- Caddy — единственная точка внешнего HTTPS, и только с доменом.
- Basic auth dashboard обязателен при внешнем bind.
- Telegram работает через исходящие соединения; входящий порт не нужен.

## Данные

`./data` соответствует `/opt/data` внутри контейнера:

- `.env`, `config.yaml`, `SOUL.md`;
- `sessions/`, `memories/`, `skills/`;
- `logs/`, `cron/`;
- `state.db`.

SQLite работает в WAL. На нативном Linux bind-mount это нормально; на virtiofs/9p (Docker Desktop) возможна порча — для VPS это не проблема, но при переносе на macOS/Windows используйте named volume.

## Секреты

- `.env` — единственное место для токенов, `chmod 600`.
- `API_SERVER_KEY` и `HERMES_DASHBOARD_BASIC_AUTH_SECRET` генерируются установщиком.
- В репозитории нет реальных значений; `.env` в `.gitignore`.

## Обновление

```text
install.sh -> docker compose pull -> up -d -> healthcheck -> smoke
```

Если healthcheck не прошёл, контейнер остаётся для диагностики; логи печатаются в консоль.

## Что не автоматизировано

- DNS и выпуск сертификата: домен должен указывать на VPS.
- Резервное копирование во внешнее хранилище: скрипт делает локальный архив.
- Мониторинг 24/7: healthcheck локальный, без алертов.

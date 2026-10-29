# Приёмка установки

Клиент получает не только работающий контейнер, но и подтверждение, что проверены основные сценарии.

## 1. До установки

- [ ] Ubuntu 22.04/24.04, есть sudo/root.
- [ ] Свободно ≥10 GB.
- [ ] Есть Telegram bot token.
- [ ] Есть ключ модели.
- [ ] Для HTTPS: домен указывает на IP VPS.

## 2. После установки

- [ ] `docker compose ps` — `hermes` в состоянии `healthy`.
- [ ] `bash scripts/smoke.sh` — `OK`.
- [ ] Dashboard открывается через SSH-туннель и просит логин/пароль.
- [ ] В Telegram бот отвечает на `/start` или обычное сообщение.
- [ ] Pairing подтверждён, если Hermes его запросил.
- [ ] `docker compose logs --tail=100 hermes` без трейсбеков.
- [ ] `./scripts/backup.sh` создаёт архив, `tar -tzf` его читает.
- [ ] `.env` имеет права `600`; в git нет `.env`.

## 3. Что передать клиенту

- SSH-команда для dashboard-туннеля.
- Логин dashboard (пароль — в менеджер паролей, не в переписку).
- Команды: logs / backup / update / uninstall.
- Список ограничений из `KWORK.md`.
- Дату и версию образа (`docker inspect hermes --format '{{.Config.Image}}'`).

## 4. Если что-то не прошло

Не сдавать работу «на словах». Сначала:

```bash
docker compose logs --tail=120 hermes
docker inspect -f '{{json .State.Health}}' hermes
docker compose config
```

Затем исправить и повторить smoke-check. Если проблема во внешнем API — зафиксировать это в отчёте, не маскировать.

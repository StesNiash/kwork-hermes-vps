# Runbook

## Первый запуск

```bash
sudo bash install.sh --with-docker
```

Если установка прервалась, повторите: существующий `.env` не перезаписывается.

## Проверка

```bash
docker compose ps
bash scripts/smoke.sh
bash scripts/healthcheck.sh
```

## Dashboard

```bash
ssh -L 9119:127.0.0.1:9119 root@<vps-ip>
```

Открыть `http://127.0.0.1:9119`, войти с логином из `.env` и паролем, который установщик напечатал один раз.

Если пароль потерян:

```bash
grep HERMES_DASHBOARD_BASIC_AUTH_PASSWORD .env
```

## Telegram не отвечает

1. Проверить, что токен от нужного бота.
2. `docker compose logs --tail=100 hermes`.
3. `docker compose exec -T hermes hermes pairing list`.
4. Подтвердить pairing.
5. Проверить, что VPS имеет исходящий интернет.

## Контейнер unhealthy

```bash
docker inspect -f '{{json .State.Health}}' hermes
docker compose logs --tail=150 hermes
```

Частые причины: пустой токен, неверный ключ модели, нехватка RAM, повреждённый `config.yaml`.
Перед экспериментами сделайте backup.

## Backup

```bash
bash scripts/backup.sh
ls -lh backups/
```

Архив содержит `./data`, включая сессии, память и навыки. Храните копию вне VPS.

## Восстановление

```bash
bash scripts/restore.sh backups/hermes-data-YYYYMMDD-HHMMSS.tar.gz
```

Текущий `data` сохраняется как `data.pre-restore-<timestamp>`.

## Обновление

```bash
bash scripts/backup.sh
bash scripts/update.sh
```

Если smoke не прошёл — вернуть предыдущий тег в `.env` (`HERMES_IMAGE_TAG`) и выполнить `docker compose up -d`.

## Удаление

```bash
bash scripts/uninstall.sh          # остановить, данные сохранить
bash scripts/uninstall.sh --purge  # удалить всё, подтверждение DELETE
```

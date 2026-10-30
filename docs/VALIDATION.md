# Validation

Дата: 2026-10-29.

## Стенд

| Параметр | Значение |
|---|---|
| ОС | Ubuntu 18.04.6 LTS (EOL, тестовый стенд) |
| CPU | 1 vCPU |
| RAM | 984 MB + 4 GB swap |
| Диск | 25 GB |
| Docker | 24.0.2 |
| Compose | 2.18.1 |
| Модель | DeepSeek `deepseek-flash` |
| Telegram | реальный тестовый бот, polling |

## Что проверено

- `install.sh --non-interactive` отработал на живом VPS.
- Контейнер `hermes` — `healthy`.
- API `/health` — `200`.
- Dashboard — `302` на страницу входа.
- Telegram: `Connected to Telegram (polling mode)`.
- Pairing подтверждён, пользователь написал боту, агент ответил.
- Прямой вызов `/v1/chat/completions` вернул `200` и корректный ответ модели.

## Найденный баг

Compose был жёстко ограничен `cpus: 2.0`; на хосте с 1 CPU Docker отказывался создавать контейнер:

```text
Range of CPUs is from 0.01 to 1.00
```

Исправлено: `cpus: ${HERMES_CPUS:-1.0}`, установщик записывает в `.env` значение `nproc`. Коммит `35655f5`.

## Ограничения теста

- Ubuntu 18.04 не входит в целевую матрицу; нужен повтор на 22.04/24.04.
- 984 MB RAM ниже рекомендуемых 2 GB; тест шёл с 4 GB swap.
- Cloud.ru не подходит для Telegram: `api.telegram.org` стабильно уходил в timeout. Этот стенд — другой провайдер, Telegram доступен.
- Токены и ключи в репозиторий не попали.

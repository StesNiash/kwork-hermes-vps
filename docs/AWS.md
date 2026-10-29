# AWS: быстрый тестовый сервер

Цель — проверить Hermes с Telegram, а не строить прод. Поэтому берём минимальную машину и останавливаем её после теста.

## Что выбрать

| Параметр | Значение |
|---|---|
| Регион | `eu-central-1` (Франкфурт) или другой вне РФ |
| Образ | Ubuntu Server 24.04 LTS |
| Инстанс | `t3.small` (2 vCPU, 2 GB) минимум |
| Диск | 20 GB gp3 |
| Security group | inbound: SSH 22 только с вашего IP; outbound: all |
| Порты 80/443 | не нужны для Telegram |

`t3.micro` (1 GB) может хватить без браузера, но Hermes с Playwright лучше на 2–4 GB. `t3.medium` (4 GB) — если планируете браузерные инструменты.

Ориентир по цене: `t3.small` в on-demand — порядка `$0.02/час`; пара долларов покрывает несколько дней работы, но точную цену смотрите в калькуляторе AWS для своего региона. Остановленный инстанс не тарифицируется как compute, но EBS-диск продолжает стоить.

## Создание

1. EC2 → Launch instance.
2. Name: `hermes-test`.
3. AMI: Ubuntu Server 24.04 LTS.
4. Instance type: `t3.small`.
5. Key pair: создайте новую пару, скачайте `.pem`.
6. Network settings: создайте security group, inbound SSH 22 → My IP. Остальное закрыто.
7. Storage: 20 GB gp3.
8. Launch.

## Подключение

```bash
chmod 600 ~/Downloads/hermes-test.pem
ssh -i ~/Downloads/hermes-test.pem ubuntu@<public-ip>
```

Проверьте, что Telegram доступен именно с этой машины:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' --max-time 10 https://api.telegram.org/
```

Ожидаемо `200` или `404`, но не `000`. Если `000` — регион/провайдер режет Telegram, машину нужно менять.

## Установка

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/StesNiash/kwork-hermes-vps.git
cd kwork-hermes-vps
sudo bash install.sh --with-docker
```

Скрипт спросит Telegram token и (опционально) ключ модели, создаст `.env`, поднимет контейнер и выполнит smoke-check.

## Dashboard

Порт `9119` не открыт в security group. Доступ через SSH-туннель:

```bash
ssh -i ~/Downloads/hermes-test.pem -L 9119:127.0.0.1:9119 ubuntu@<public-ip>
# открыть http://127.0.0.1:9119
```

## После теста

```bash
cd kwork-hermes-vps
sudo bash scripts/backup.sh
sudo bash scripts/uninstall.sh --purge
```

Затем в EC2: Instance state → Stop (или Terminate, если диск больше не нужен).

## Что проверить

- [ ] `curl https://api.telegram.org/` не timeout.
- [ ] `docker compose ps` — `healthy`.
- [ ] `bash scripts/smoke.sh` — OK.
- [ ] Бот отвечает в Telegram.
- [ ] Dashboard открывается через туннель.
- [ ] `.env` имеет права `600`.

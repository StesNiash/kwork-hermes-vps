# KWORK — Hermes Agent на VPS

## Карточка

**Название:** Установлю и настрою AI-агента Hermes на вашем сервере

**Цена:** 2 500 ₽

**Срок:** 1 день

**Что входит:**

- установка Hermes Agent на Ubuntu 22.04/24.04;
- Docker Compose и `.env` с правами `600`;
- первичная настройка выбранной AI-модели;
- Telegram-бот: подключение, pairing, проверка сообщения;
- dashboard, доступный через SSH-туннель;
- автозапуск и healthcheck;
- backup, restore, update и uninstall;
- короткая инструкция владельцу.

**Что нужно от покупателя:**

- SSH-доступ к VPS (root или sudo);
- Telegram bot token от @BotFather;
- API-ключ модели (OpenRouter / Anthropic / OpenAI / другой провайдер);
- VPS с исходящим доступом к `api.telegram.org:443` (иначе нужен зарубежный сервер или разрешённый прокси);
- домен — только если нужен HTTPS-dashboard.

**Допы:**

- дополнительная настройка под процесс — 6 000 ₽;
- поддержка на неделю — 12 000 ₽;
- несколько профилей/ботов — оценивается отдельно.

## Что не входит

- Стоимость VPS, API-запросов, домена и прокси.
- Обход лимитов провайдера или оплата чужих подписок.
- Бессрочная поддержка.
- Публикация dashboard в интернет без TLS и пароля.
- Обещание, что агент «сам всё сделает»: качество зависит от модели, ключей и задач.

## Что говорить при заказе

1. Уточнить ОС и версию, RAM/диск, есть ли Docker.
2. Уточнить провайдера модели и есть ли ключ.
3. Уточнить, нужен ли только Telegram или ещё dashboard/API.
4. Предупредить: для HTTPS нужен домен и DNS.
5. После установки прислать чек-лист приёмки из `docs/ACCEPTANCE.md`.

## Что не обещать

- «Полная автономность» и «самообучение без ограничений».
- Работу с любым провайдером без проверки.
- Сохранность данных без backup.
- Поддержку 24/7 в базовой цене.

## Обложка (не копировать в карточку)

> Это промпт для генератора изображений, а не текст объявления. В Kwork его публиковать не нужно.

**Промпт для ChatGPT / Gemini:**

> 4:3 cover illustration for a freelance service that installs a personal AI agent on a client's VPS. On the left, a clean compact server box with a subtle SSH terminal; on the right, a minimal browser dashboard and a Telegram-style chat bubble connected by a secure glowing line. In the center, an abstract friendly AI assistant orb, not a human face. Deep navy background, teal and warm amber accents, soft rim light, subtle grid, professional editorial tech style, high contrast, generous negative space, centered composition that survives a square crop, no text, no letters, no logos, no watermarks, no real person, crisp 3D-isometric mixed with clean vector.

**Коротко по-русски:** сервер + защищённая линия + дашборд/Telegram + абстрактный AI-ассистент; тёмно-синий, бирюза и янтарь; без текста и логотипов.

**Параметры:** 1200×900, 4:3; главный объект по центру, важные детали не у краёв.

**Негатив:** text, typography, letters, logo, brand mark, watermark, signature, real face, clutter, busy background, low contrast, distorted hands.

**Если нужен исходник:** не берите чужие скриншоты и логотип Hermes. Для реального кадра снимите свой dashboard после установки, без токенов, чатов и персональных данных; либо используйте нейтральную схему «VPS → Hermes → Telegram». Логотип и товарные знаки — только с разрешения правообладателя.

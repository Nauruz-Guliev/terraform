# Инструкция по использованию YandexGPT API

Эта инструкция содержит шаги для использования YandexGPT API с помощью Terraform и CLI для генерации текстовых ответов.

## Установка и настройка

1. **Установка и настройка CLI**
    - Скачайте и установите CLI для взаимодействия с Yandex Cloud. [Подробная инструкция](https://yandex.cloud/ru/docs/cli/quickstart#install).

2. **Создание сервисного аккаунта**
    - Создайте сервисный аккаунт для использования YandexGPT. [Инструкция](https://yandex.cloud/ru/docs/iam/operations/sa/create#cli_1).

3. **Получение IAM-токена**
    - Сгенерируйте IAM-токен для сервисного аккаунта для авторизации запросов. [Инструкция](https://yandex.cloud/ru/docs/iam/operations/iam-token/create-for-sa).

## Конфигурация Terraform

4. **Подготовка к работе с Terraform**
    - Ознакомьтесь с основами работы с Terraform. [Инструкция](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart).

5. **Хранение токенов и идентификаторов**
    - Сохраните IAM-токен и `folder-id` в переменных Terraform, используя файл `.tfvars` для управления конфиденциальной информацией. [Как получить folder-id](https://yandex.cloud/ru/docs/resource-manager/operations/folder/get-id).

## Выполнение запросов к YandexGPT

6. **Формирование запроса**
    - Подготовьте JSON-запрос для API.
```json
{
  "modelUri": "gpt://<folder-id>/yandexgpt-lite",
  "completionOptions": {
    "stream": false,
    "temperature": 0.6,
    "maxTokens": "2000"
  },
  "messages": [
    {
      "role": "system",
      "text": "Ты - преподаватель курса Операционные системы. Тебе отправляют текст билета. Твоя задача - максимально подробно раскрыть тему билета на русском языке, чтобы оценка была 100 из 100. Ответ будет отправляться в мессенджер телеграм, поэтому форматирование должно соответствовать правилам форматирования телеграма."
    },
    {
      "role": "user",
      "text": "Управление вводом-выводом: Систематизация внешних устройств и интерфейс между базовой подсистемой ввода-вывода и драйверами. Кооперация процессов: Сообщения."
    }
  ]
}
```
* `modelUri`: Идентификатор модели для генерации ответа.
* `completionOptions`: Настройки генерации текста, включая temperature и maxTokens.
* `messages`: Массив, включающий контексты диалога для модели.
7. Отправка запроса
   Пример использования curl для отправки запроса. Трансформируйте этот вызов в код на вашем языке программирования.
```
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <IAM токен>" \
  --data '<Тело запроса>' \
  "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
```
## Получение ответа
8. **Обработка ответа**
    - Сервер вернет JSON с сгенерированным ответом. Пример структуры ответа:
```json
{
  "result": {
    "alternatives": [
      {
        "message": {
          "role": "assistant",
          "text": "..."
        },
        "status": "ALTERNATIVE_STATUS_TRUNCATED_FINAL"
      }
    ],
    "usage": {
      "inputTextTokens": "67",
      "completionTokens": "50",
      "totalTokens": "117"
    },
    "modelVersion": "06.12.2023"
  }
}
```

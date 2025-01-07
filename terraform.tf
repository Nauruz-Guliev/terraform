terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
  folder_id = var.yandex_folder_id
  cloud_id = var.yandex_cloud_id
  service_account_key_file = "/Users/nauruz/Documents/hw-bot/terraform/key.json"
}

resource "yandex_function" "telegram-bot-function" {
    name               = "telegram-bot-function"
    description        = "Telegram bot function"
    user_hash          = "${data.archive_file.zip.output_sha512}"
    runtime            = "kotlin20"
    entrypoint         = "Handler"
    memory             = "128"
    execution_timeout  = "40"
    environment = {
        OCR_TOKEN      = var.ocr_token 
        FOLDER_ID      = var.yandex_folder_id
        TELEGRAM_TOKEN = var.tg_bot_key
        GPT_TOKEN      = var.gpt_token
    }
    content {
        zip_filename = "${data.archive_file.zip.output_path}"
    }
}

resource "yandex_function_iam_binding" "function_public_access" {
  function_id = yandex_function.telegram_bot_function.id
  role        = "functions.functionInvoker"
  members = [
    "system:allUsers",
  ]
}

resource "yandex_storage_bucket" "bucket" {
  bucket = "gnt-bucket"
}

# загрузка readme в отдельный бакет
resource "yandex_storage_object" "readme" {
  bucket = yandex_storage_bucket.bucket.bucket
  key    = "readme.md"
  source = "/Users/nauruz/Documents/hw-bot/terraform-repo/readme.md" 
}

# создает zip-архив с целым котлин проектом
# так как ссылается на весь репозиторий, необходимо также исключать файлы, которые не нужны для сборки в облаке
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "/Users/nauruz/Documents/hw-bot/telegram-bot/"
  output_path = "../archive.zip"
  
  excludes = [
    "**/.gradle/**",
    "**/.kotlin/**",
    "**/.idea/**",
    "**/.git/**",
    "**/build/**",
    "**/gradle/**",
    "**/.gitignore",
    "**/gradle.properties",
    "**/gradlew",
    "**/gradlew.bat"
  ]
}

# помимо установки вебхука отменяются прошлые обновления с помощью параметра drop_pending_updates = true
# сделано это для того, чтобы проще было разрабатывать
# при новом деплое через terraform apply старые сообщения не будут отправляться в новый деплой
data http telegram_set_webhook {
  url = "https://api.telegram.org/bot${var.tg_bot_key}/setWebhook?drop_pending_updates=true&url=https://functions.yandexcloud.net/${yandex_function.telegram-bot-function.id}"
  method = "GET"
}

# возможно, есть более элегантное решение удаления вебхука, но я его не нашел
resource "null_resource" "on_destroy" {
  provisioner "local-exec" {
    command = <<EOT
      if [ "${self.triggers.destroy_phase}" = "true" ]; then
        curl -X GET "https://api.telegram.org/bot${var.tg_bot_key}/deleteWebhook"
      fi
    EOT
  }

  triggers = {
    destroy_phase = "${terraform.workspace == "destroy" ? "true" : "false"}"
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}

output "destroy_execution" {
  value = null_resource.on_destroy.id
}

variable "tg_bot_key" {
  description = "Токен для телеграма."
  type        = string
  sensitive   = true
}

variable "yandex_folder_id" {
  description = "Folder ID."
  type        = string
  default = "b1g11gq2080qsump1g47"
}

variable "yandex_cloud_id" {
  description = "Cloud ID."
  type        = string
  default = "b1g71e95h51okii30p25"
}

variable "gpt_token" {
  description = "Токен для Yandex GPT."
  type        = string
  sensitive   = true
}

variable "ocr_token" {
  description = "Токен для Yandex OCR."
  type        = string
  sensitive   = true
}
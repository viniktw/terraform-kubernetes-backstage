variable "app_name" {
  description = "This will be used for a namespace"
}

variable "my_domain" {
  description = "This will be used for creating ingresses"
}

variable "my_backstage_image" {}

variable "github_token" {}

variable "github_auth_client_id" {}

variable "github_auth_client_secret" {}

variable "db_user" {}

variable "db_password" {}

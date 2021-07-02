variable "app_name" {
  default = "backstage"
  description = "This will be used for a namespace, subdomain, prefix, etc"
}

variable "my_domain" {
  description = "This will be used for creating ingresses"
}

variable "my_backstage_image" {
  default="vinik/backstage:latest"
}

variable "github_token" {}

variable "github_auth_client_id" {}

variable "github_auth_client_secret" {}

variable "db_user" {
  default = "backstage"
}

variable "db_password" {
  default = "b@ckst4g3"
}

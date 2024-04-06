variable "github_owner" {
  type        = string
  description = "GitHub repository owner"
  default     = "mopeneko"
}

variable "package_name" {
  type        = string
  description = "Package name"
  default     = "mopetube"
}

variable "domain_name" {
  type        = string
  description = "Domain name"
  default     = "mopetube.com"
}

variable "vpc_flow_log_role_arn" {
  type        = string
  description = "VPC Flow Log role ARN"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ECS task execution role ARN"
}

variable "github_token" {
  type        = string
  description = "GitHub token"
}

variable "db_host" {
  type        = string
  description = "Database host"
}

variable "db_port" {
  type        = string
  description = "Database port"
}

variable "db_user" {
  type        = string
  description = "Database user"
}

variable "db_pass" {
  type        = string
  description = "Database password"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "pepper" {
  type        = string
  description = "Pepper for hashing"
}

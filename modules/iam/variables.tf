variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "enable_ssm_access" {
  description = "Enable SSM access for node groups (useful for debugging)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


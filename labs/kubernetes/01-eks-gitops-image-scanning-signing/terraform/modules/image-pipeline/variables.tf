variable "name_prefix" {
  description = "Start of every name, e.g. k8slab01-dev"
  type        = string
}

variable "app_name" {
  description = "The app whose images these repositories hold, e.g. sample-web-app"
  type        = string
}

variable "force_destroy" {
  description = "Let terraform destroy delete repositories that still hold images (false in prd)"
  type        = bool
}

variable "candidate_images_to_keep" {
  description = "How many builds the candidate repository keeps; older ones expire"
  type        = number
  default     = 30
}

variable "project_id" {
  type           = string
  description  = "Project ID"
  default        = "kubernetes-414808"
}

variable "region" {
  type           = string
  description  = "Region for this infrastructure"
  default        = "us-west1"
}

variable "name" {
  type           = string
  description  = "Name for this infrastructure"
  default       = "kubernetes-the-hard-way"
}

variable "ip_cidr_range" {
  type         = string
  description  = "List of The range of internal addresses that are owned by this subnetwork."
  default      = "10.240.0.0/24"
}
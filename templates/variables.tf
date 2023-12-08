variable "region" {
  description = "Region where to deploy the DNS Automation resources"
  type        = string
}

variable "environment" {
  type        = string
  description = "The environment of the DNS Automation resources"
}

variable "vpc_name" {
  description = "Name of the DNS VPC"
  type        = string
}

variable "excluded_subnets" {
  description = "Comma separated list of subnets containing EC2 instances that must be excluded from the automatic DNS registration process"
  type        = string
}

variable "org_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "infoblox_api_user" {
  description = "Infoblox API IP user name"
  type        = string
}

variable "infoblox_api_password" {
  description = "Infoblox API Password"
  type        = string
  sensitive   = true
}

variable "infoblox_api_ip_read" {
  description = "Infoblox API IP for read operations"
  type        = string
  default     = null
}

variable "infoblox_api_ip" {
  description = "Infoblox API IP for write operations. Please note that we will use this IP for Read opperations if `infoblox_api_ip_read` variable is not provided"
  type        = string
}

variable "dns_view" {
  description = "Infoblox DNS Zone View"
  type        = string
}

variable "extensible_attribute_name" {
  description = "Infoblox Extensible Attribute name to use for the EC2 Instance ID"
  type        = string
}

variable "audit_config_aggregator_assume_role_arn" {
  description = "Role to assume in the Audit account to access the Config aggregator"
  type        = string
}

variable "audit_config_aggregator_name" {
  description = "Config aggregator name in the Audit account"
  type        = string
}

variable "audit_config_aggregator_region" {
  description = "Region where the Config aggregator is located in the Audit account"
  type        = string
}

variable "permissions_boundary_arn" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM roles"
  type        = string
}

variable "python_runtime_version" {
  description = "Python runtime to be used by lambda function"
  type        = string
}

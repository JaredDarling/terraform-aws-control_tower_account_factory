# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

variable "account_factory_product_name" {
  type = string
}

variable "aft_account_provisioning_framework_sfn_name" {
  type = string
}

variable "aft_tf_aws_customizations_module_url_ssm_path" {
  type = string
}

variable "aft_tf_aws_customizations_module_git_ref_ssm_path" {
  type = string
}

variable "aft_create_vpc" {
  default     = true
  description = "Create VPC or use existing. Include aft_vpc_config for existing."
  type        = bool
}

variable "aft_version" {
  type = string
}

variable "aft_vpc_config" {
  default = {
    subnet_ids = []
    vpc_id     = ""
  }
  description = "Used when aft_create_vpc=true"
  type = object({
    subnet_ids = list(string)
    vpc_id     = string
  })
}

variable "aft_vpc_cidr" {
  type = string
}

variable "aft_vpc_private_subnet_01_cidr" {
  type = string
}

variable "aft_vpc_private_subnet_02_cidr" {
  type = string
}

variable "aft_vpc_public_subnet_01_cidr" {
  type = string
}

variable "aft_vpc_public_subnet_02_cidr" {
  type = string
}

variable "aft_vpc_endpoints" {
  type = bool
}

variable "builder_archive_path" {
  type = string
}

variable "builder_archive_hash" {
  type = string
}

variable "cloudwatch_log_group_retention" {
  type = string
}

variable "ct_home_region" {
  type = string
}

variable "enable_auto_account_request" {
  type = bool
}

variable "request_framework_archive_path" {
  type = string
}

variable "request_framework_archive_hash" {
  type = string
}
variable "concurrent_account_factory_actions" {
  type = number
}

# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
locals {
  build_project_name              = "python-layer-builder-${var.lambda_layer_name}-${random_string.resource_suffix.result}"
  account_id                      = data.aws_caller_identity.session.account_id
  target_id                       = "trigger_build"
  codebuild_invoker_function_name = "aft-lambda-layer-codebuild-invoker"
  lambda_layer_version            = replace(var.aft_version, ".", "-")
  lambda_layer_name_versioned     = "${var.lambda_layer_name}-${local.lambda_layer_version}-${random_string.layer_suffix.result}"
}

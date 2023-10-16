# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
output "aft_customizations_identify_targets_function_arn" {
  value = aws_lambda_function.aft_customizations_identify_targets.arn
}

output "aft_customizations_execute_pipeline_function_arn" {
  value = aws_lambda_function.aft_customizations_execute_pipeline.arn
}

output "aft_customizations_get_pipeline_executions_function_arn" {
  value = aws_lambda_function.aft_customizations_get_pipeline_executions.arn
}
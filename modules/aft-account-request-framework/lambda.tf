# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

module "aft_lambda_layer" {
  source                                            = "./modules/aft-lambda-layer"
  aft_version                                       = var.aft_version
  lambda_layer_name                                 = local.lambda_layer_name
  lambda_layer_codebuild_delay                      = local.lambda_layer_codebuild_delay
  lambda_layer_python_version                       = local.lambda_layer_python_version
  aft_tf_aws_customizations_module_git_ref_ssm_path = var.aft_tf_aws_customizations_module_git_ref_ssm_path
  aft_tf_aws_customizations_module_url_ssm_path     = var.aft_tf_aws_customizations_module_url_ssm_path
  aws_region                                        = var.ct_home_region
  aft_kms_key_arn                                   = aws_kms_key.aft.arn
  aft_vpc_id                                        = local.vpc_id
  aft_vpc_private_subnets                           = local.private_subnet_ids
  aft_vpc_default_sg                                = local.default_security_group_ids
  s3_bucket_name                                    = aws_s3_bucket.aft_codepipeline_customizations_bucket.id
  builder_archive_path                              = var.builder_archive_path
  builder_archive_hash                              = var.builder_archive_hash
  cloudwatch_log_group_retention                    = var.cloudwatch_log_group_retention
}

######## aft_account_request_audit_trigger ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_account_request_audit_trigger" {
  filename      = var.request_framework_archive_path
  function_name = "aft-account-request-audit-trigger"
  description   = "Receives trigger from DynamoDB aft-request table and inserts the event into aft-request-audit table"
  role          = aws_iam_role.aft_account_request_audit_trigger.arn
  handler       = "aft_account_request_audit_trigger.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [aws_dynamodb_table.aft_request, aws_lambda_function.aft_account_request_audit_trigger]
  create_duration = "60s"
}

resource "aws_lambda_event_source_mapping" "aft_account_request_audit_trigger" {
  depends_on             = [time_sleep.wait_60_seconds]
  event_source_arn       = aws_dynamodb_table.aft_request.stream_arn
  function_name          = aws_lambda_function.aft_account_request_audit_trigger.arn
  starting_position      = "LATEST"
  batch_size             = 1
  maximum_retry_attempts = 1
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_account_request_audit_trigger" {
  name              = "/aws/lambda/${aws_lambda_function.aft_account_request_audit_trigger.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

######## aft_account_request_action_trigger ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_account_request_action_trigger" {

  filename      = var.request_framework_archive_path
  function_name = "aft-account-request-action-trigger"
  description   = "Receives trigger from DynamoDB aft-request table and determines action target - SQS or Lambda aft-invoke-aft-account-provisioning-framework"
  role          = aws_iam_role.aft_account_request_action_trigger.arn
  handler       = "aft_account_request_action_trigger.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }

}

resource "aws_lambda_event_source_mapping" "aft_account_request_action_trigger" {
  event_source_arn       = aws_dynamodb_table.aft_request.stream_arn
  function_name          = aws_lambda_function.aft_account_request_action_trigger.arn
  starting_position      = "LATEST"
  batch_size             = 1
  maximum_retry_attempts = 1
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_account_request_action_trigger" {
  name              = "/aws/lambda/${aws_lambda_function.aft_account_request_action_trigger.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

######## aft_controltower_event_logger ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_controltower_event_logger" {

  filename      = var.request_framework_archive_path
  function_name = "aft-controltower-event-logger"
  description   = "Receives Control Tower events through dedicated event bus event and writes event to aft-controltower-events table"
  role          = aws_iam_role.aft_controltower_event_logger.arn
  handler       = "aft_controltower_event_logger.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }
}

resource "aws_lambda_permission" "aft_controltower_event_logger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aft_controltower_event_logger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aft_controltower_event_trigger.arn
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_controltower_event_logger" {
  name              = "/aws/lambda/${aws_lambda_function.aft_controltower_event_logger.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

######## aft_account_request_processor ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_account_request_processor" {

  filename      = var.request_framework_archive_path
  function_name = "aft-account-request-processor"
  description   = "Triggered by CW Event, reads aft-account-request.fifo queue and performs needed action"
  role          = aws_iam_role.aft_account_request_processor.arn
  handler       = "aft_account_request_processor.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }

}

resource "aws_lambda_permission" "aft_account_request_processor" {
  count         = var.enable_auto_account_request ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aft_account_request_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aft_account_request_processor[0].arn
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_account_request_processor" {
  name              = "/aws/lambda/${aws_lambda_function.aft_account_request_processor.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

######## aft_invoke_aft_account_provisioning_framework ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_invoke_aft_account_provisioning_framework" {

  filename      = var.request_framework_archive_path
  function_name = "aft-invoke-aft-account-provisioning-framework"
  description   = "Calls AFT Account Provisioning Framework Step Function based on a formatted incoming event from Lambda or CW Event"
  role          = aws_iam_role.aft_invoke_aft_account_provisioning_framework.arn
  handler       = "aft_invoke_aft_account_provisioning_framework.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }

}

resource "aws_lambda_permission" "aft_invoke_aft_account_provisioning_framework" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aft_invoke_aft_account_provisioning_framework.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aft_controltower_event_trigger.arn
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_invoke_aft_account_provisioning_framework" {
  name              = "/aws/lambda/${aws_lambda_function.aft_invoke_aft_account_provisioning_framework.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

######## aft_cleanup_resources ########

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "aft_cleanup_resources" {

  filename      = var.request_framework_archive_path
  function_name = "aft-cleanup-resources"
  description   = "Removes AFT pipeline resources when an account record is removed from the AFT repo"
  role          = aws_iam_role.aft_cleanup_resources.arn
  handler       = "aft_cleanup_resources.lambda_handler"

  source_code_hash = var.request_framework_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = local.default_lambda_timeout
  layers           = [module.aft_lambda_layer.layer_version_arn]

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = local.default_security_group_ids
  }

}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "aft_cleanup_resources" {
  name              = "/aws/lambda/${aws_lambda_function.aft_cleanup_resources.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

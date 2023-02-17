# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

resource "aws_codebuild_project" "lambda_layer_codebuild" {
  name           = local.build_project_name
  description    = "Codebuild project to create lambda layer ${var.lambda_layer_name}"
  build_timeout  = "10"
  service_role   = aws_iam_role.codebuild.arn
  encryption_key = var.aft_kms_key_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    privileged_mode             = false
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "PYTHON_VERSION"
      value = var.lambda_layer_python_version
    }
    environment_variable {
      name  = "LAYER_NAME"
      value = local.lambda_layer_name_versioned
    }
    environment_variable {
      name  = "BUCKET_NAME"
      value = var.s3_bucket_name
    }
    environment_variable {
      name  = "EVENT_RULE_NAME"
      value = "${local.build_project_name}-${local.lambda_layer_version}"
    }
    environment_variable {
      name  = "EVENT_TARGET_ID"
      value = local.target_id
    }
    environment_variable {
      name  = "SSM_AWS_MODULE_SOURCE"
      value = var.aft_tf_aws_customizations_module_url_ssm_path
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "SSM_AWS_MODULE_GIT_REF"
      value = var.aft_tf_aws_customizations_module_git_ref_ssm_path
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "AWS_PARTITION"
      value = data.aws_partition.current.partition
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.lambda_layer_codebuild.name
      stream_name = "build-logs"
      status      = "ENABLED"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = data.local_file.aft_lambda_layer.content
  }

  vpc_config {
    vpc_id             = var.aft_vpc_id
    subnets            = var.aft_vpc_private_subnets
    security_group_ids = var.aft_vpc_default_sg
  }

  lifecycle {
    ignore_changes = [project_visibility]
  }
}

resource "aws_cloudwatch_log_group" "lambda_layer_codebuild" {
  name              = "/aws/codebuild/${local.build_project_name}"
  retention_in_days = var.cloudwatch_log_group_retention
}
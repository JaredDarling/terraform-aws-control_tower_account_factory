# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
locals {
  lambda_managed_policies = [
    data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn,
    data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn
  ]

  public_subnet_ids          = var.aft_create_vpc ? tolist([aws_subnet.aft_vpc_public_subnet_01[0].id, aws_subnet.aft_vpc_public_subnet_02[0].id]) : []
  private_subnet_ids         = var.aft_create_vpc ? tolist([aws_subnet.aft_vpc_private_subnet_01[0].id, aws_subnet.aft_vpc_private_subnet_02[0].id]) : var.aft_vpc_config.subnet_ids
  default_security_group_ids = tolist([aws_security_group.aft_vpc_default_sg.id])
  endpoint_sg_id             = var.aft_create_vpc ? aws_security_group.aft_vpc_endpoint_sg[0].id : ""
  vpc_id                     = var.aft_create_vpc ? aws_vpc.aft_vpc[0].id : var.aft_vpc_config.vpc_id
  default_lambda_timeout     = "30"

  lambda_layer_codebuild_delay = "420s"
  lambda_layer_python_version  = "3.8"
  lambda_layer_name            = "aft-common"
}

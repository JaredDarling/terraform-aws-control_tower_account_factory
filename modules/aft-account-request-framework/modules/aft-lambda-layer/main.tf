# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
resource "random_string" "resource_suffix" {
  length  = "8"
  lower   = true
  upper   = false
  special = false
}

resource "random_string" "layer_suffix" {
  length  = "6"
  lower   = true
  upper   = false
  special = false
  number  = true
  keepers = {
    layer_code_sha256 = sha1(join("", [for f in fileset(path.root, "sources/aft-lambda-layer/**") : filesha1(f)]))
  }
}

resource "aws_lambda_layer_version" "layer_version" {
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [data.aws_lambda_invocation.invoke_codebuild_job]

  layer_name          = local.lambda_layer_name_versioned
  compatible_runtimes = ["python${var.lambda_layer_python_version}"]
  s3_bucket           = var.s3_bucket_name
  s3_key              = "${local.lambda_layer_name_versioned}.zip"
}

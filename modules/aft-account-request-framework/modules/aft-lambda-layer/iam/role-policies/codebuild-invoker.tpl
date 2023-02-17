{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
      ],
      "Effect": "Allow",
      "Resource": "arn:${data_aws_partition_current_partition}:codebuild:${aws_region}:${account_id}:project/${codebuild_project_name}"
    },
    {
      "Action": [
          "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "arn:${data_aws_partition_current_partition}:logs:${aws_region}:${account_id}:*"
    },
    {
      "Action": [
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:${data_aws_partition_current_partition}:logs:${aws_region}:${account_id}:log-group:/aws/lambda/${codebuild_invoker_function_name}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:${data_aws_partition_current_partition}:s3:::${s3_bucket_name}",
        "arn:${data_aws_partition_current_partition}:s3:::${s3_bucket_name}/*"
      ]
    }
  ]
}

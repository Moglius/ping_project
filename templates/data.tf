data "git_repository" "dns_automation" {
  path = path.root
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "lambda" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "lambda" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}*"]
  }
}

data "aws_iam_policy_document" "cmk_eventbridge_lambda" {
  statement {
    sid    = "Allow EventBridge and Lambda Access"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        module.eventbridge_custom.eventbridge_rule_arns.ec2_event_custom,
        module.eventbridge_default.eventbridge_rule_arns.ec2_event_default,
        "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${local.name}-lambda"
      ]
    }
  }

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "cmk_lambda" {
  statement {
    sid    = "Allow Lambda Access"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${local.name}-lambda"
      ]
    }
  }

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  #checkov:skip=CKV_AWS_356: All resources are allowed for some ec2 and xray actions that do not support resource-level permissions.
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name}-lambda:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
      module.sqs_ec2_events.queue_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      var.audit_config_aggregator_assume_role_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.sqs_ec2_events.arn,
      aws_kms_key.infoblox_secret.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.infoblox.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:security-group/*"

    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    #checkov:skip=CKV_AWS_111: All resources are allowed for some ec2 and xray actions that do not support resource-level permissions.
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "eventbus_policy" {
  statement {
    sid    = "OrganizationAccess"
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListRules",
      "events:ListTargetsByRule",
      "events:ListTagsForResource",
      "events:PutEvents"
    ]
    resources = [module.eventbridge_custom.eventbridge_bus_arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.org_id, ]
    }
  }
}

data "aws_lambda_function" "dns_automation" {
  depends_on    = [module.lambda]
  function_name = module.lambda.lambda_function_name
}

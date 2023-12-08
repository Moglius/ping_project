provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

################################################################################
# EventBridge Custom Bus with EC2 events rule
################################################################################

module "eventbridge_custom" {
  source = "github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=c72cd4757bd4fc828f69fc9a92daa643e0938d42"

  bus_name                  = "${local.name}-custom-eventbus"
  role_permissions_boundary = var.permissions_boundary_arn

  rules = {
    ec2_event_custom = {
      description   = "Capture all EC2 Instance State change"
      event_pattern = local.eventbridge_ec2_event_pattern
      enabled       = true
    }
  }

  targets = {
    ec2_event_custom = [
      {
        name       = "${local.name}-sqs-ec2-event-target"
        arn        = module.sqs_ec2_events.queue_arn
        input_path = "$.detail"
      }
    ]
  }
}

################################################################################
# EventBridge Default Bus EC2 events rule
################################################################################

module "eventbridge_default" {
  source = "github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=c72cd4757bd4fc828f69fc9a92daa643e0938d42"

  create_bus  = false
  create_role = false

  rules = {
    ec2_event_default = {
      description   = "Capture all EC2 Instance State change"
      event_pattern = local.eventbridge_ec2_event_pattern
      enabled       = true
    }
  }

  targets = {
    ec2_event_default = [
      {
        name       = "${local.name}-sqs-ec2-event-target"
        arn        = module.sqs_ec2_events.queue_arn
        input_path = "$.detail"
      }
    ]
  }
}

resource "aws_cloudwatch_event_bus_policy" "eventbuspolicy" {
  policy         = data.aws_iam_policy_document.eventbus_policy.json
  event_bus_name = module.eventbridge_custom.eventbridge_bus_name
}

################################################################################
# SQS Queue
################################################################################

resource "aws_kms_key" "sqs_ec2_events" {
  description             = "DNS Automation EC2 Events SQS Queue CMK"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk_eventbridge_lambda.json
}

resource "aws_kms_alias" "sqs_ec2_events_cmk" {
  name          = "alias/${local.name}-sqs-ec2-events-cmk"
  target_key_id = aws_kms_key.sqs_ec2_events.key_id
}

module "sqs_ec2_events" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=e195083299253cb5872ea5154614d759baf5a5fb"

  name                              = "${local.name}-sqs-ec2-events"
  kms_master_key_id                 = aws_kms_key.sqs_ec2_events.key_id
  kms_data_key_reuse_period_seconds = 3600
  visibility_timeout_seconds        = 900
  message_retention_seconds         = 345600
  create_dlq                        = true
  redrive_policy = {
    maxReceiveCount = 2
  }
  create_queue_policy = true
  queue_policy_statements = {
    eventbridge_rules = {
      sid     = "eventbridge_rules"
      actions = ["sqs:SendMessage"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [
            "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/ec2-event-default-rule",
            "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/${local.name}-custom-eventbus/ec2-event-custom-rule"
          ]
        }
      ]
    },
    enforce_intransit_encrypt = {
      sid     = "enforce_intransit_encrypt"
      actions = ["sqs:SendMessage", "sqs:ReceiveMessage"],
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      resources = ["arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name}-sqs-ec2-events"]
      conditions = [
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["false"]
        }
      ]
      effect = "Deny"
    }
  }

}

################################################################################
# Lambda Function Build packages
################################################################################

resource "aws_kms_key" "lambda_package" {
  description             = "KMS key is used to encrypt Lambda package S3 bucket objects"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk_lambda.json
}

resource "aws_kms_alias" "lambda_package" {
  name          = "alias/${local.name}-lambda-package-cmk"
  target_key_id = aws_kms_key.lambda_package.key_id
}

module "s3_bucket_lambda_package" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c074ef4870aa981aafa5824f377f493377b7ee7f"

  bucket_prefix = "${local.name}-package-"
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.lambda_package.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "lambda_package" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=5b2eb57af40980ed9d7165ab04fb1ed4f44ec206"

  create_function = false

  runtime = var.python_runtime_version
  source_path = [
    {
      path             = "${path.root}/lambda"
      pip_requirements = true
    }
  ]
}

resource "aws_s3_object" "unsigned_lambda_package" {
  bucket = module.s3_bucket_lambda_package.s3_bucket_id
  key    = "unsigned/${replace(module.lambda_package.local_filename, "builds/", "")}"
  source = "${path.root}/${module.lambda_package.local_filename}"

  # Making sure that S3 versioning configuration is propagated properly
  depends_on = [
    module.s3_bucket_lambda_package
  ]
}

################################################################################
# Lambda Function Code Signing
################################################################################

resource "random_pet" "this" {
  length = 2
}

resource "aws_signer_signing_profile" "lambda_package" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  # invalid value for name (must be alphanumeric with max length of 64 characters)
  name = replace("${local.name}${random_pet.this.id}", "-", "")

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }
}

resource "aws_lambda_code_signing_config" "lambda_package" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_package.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_signer_signing_job" "lambda_package" {
  profile_name = aws_signer_signing_profile.lambda_package.name

  source {
    s3 {
      bucket  = module.s3_bucket_lambda_package.s3_bucket_id
      key     = aws_s3_object.unsigned_lambda_package.id
      version = aws_s3_object.unsigned_lambda_package.version_id
    }
  }

  destination {
    s3 {
      bucket = module.s3_bucket_lambda_package.s3_bucket_id
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = true
}

################################################################################
# Lambda Function
################################################################################
module "security_group_lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=43974e94067251ee464018288aa44862d0adba22"

  name        = "${local.name}-sg"
  description = "Security group for lambda to reach Infoblox"
  vpc_id      = data.aws_vpc.lambda.id

  egress_cidr_blocks = formatlist("%s/32", local.infoblox_endpoints_ips)
  egress_rules       = ["https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      description = "Allow Outbound HTTPS to reach VPC Endpoints in Shared Network Account"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=5b2eb57af40980ed9d7165ab04fb1ed4f44ec206"

  function_name                  = "${local.name}-lambda"
  handler                        = "index.lambda_handler"
  runtime                        = var.python_runtime_version
  code_signing_config_arn        = aws_lambda_code_signing_config.lambda_package.arn
  create_package                 = false
  tracing_mode                   = "Active"
  timeout                        = 600
  reserved_concurrent_executions = 100
  attach_policy_json             = true
  policy_json                    = data.aws_iam_policy_document.lambda.json
  role_permissions_boundary      = var.permissions_boundary_arn
  vpc_subnet_ids                 = data.aws_subnets.lambda.ids
  vpc_security_group_ids         = [module.security_group_lambda.security_group_id]

  s3_existing_package = {
    bucket = aws_signer_signing_job.lambda_package.signed_object[0].s3[0].bucket
    key    = aws_signer_signing_job.lambda_package.signed_object[0].s3[0].key
  }

  environment_variables = {
    IB_API_IP_READ                          = var.infoblox_api_ip_read
    IB_API_IP                               = var.infoblox_api_ip
    INFOBLOX_USER                           = var.infoblox_api_user
    INFOBLOX_SECRET                         = aws_secretsmanager_secret.infoblox.name
    AUDIT_CONFIG_AGGREGATOR_ASSUME_ROLE_ARN = var.audit_config_aggregator_assume_role_arn
    AUDIT_CONFIG_AGGREGATOR_NAME            = var.audit_config_aggregator_name
    AUDIT_CONFIG_AGGREGATOR_REGION          = var.audit_config_aggregator_region
    DNS_VIEW                                = var.dns_view
    EXTENSIBLE_ATTRIBUTE_NAME               = var.extensible_attribute_name
    EXCLUDED_SUBNETS                        = var.excluded_subnets
  }

  event_source_mapping = {
    sqs_ec2_events = {
      event_source_arn = module.sqs_ec2_events.queue_arn
    }
  }

  allowed_triggers = {
    sqs_ec2_events = {
      service    = "sqs"
      source_arn = module.sqs_ec2_events.queue_arn
    }
  }

  publish = true
}

################################################################################
# Secrets Manager for Infoblox Secrets
################################################################################

resource "aws_kms_key" "infoblox_secret" {
  description             = "DNS Automation Infoblox Secrets Manager CMK"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk_lambda.json
}

resource "aws_kms_alias" "infoblox_secret_cmk" {
  name          = "alias/${local.name}-infoblox-secret-cmk"
  target_key_id = aws_kms_key.infoblox_secret.key_id
}

resource "aws_secretsmanager_secret" "infoblox" {
  #checkov:skip=CKV2_AWS_57: Infoblox API automation user password cannot have automatic rotation enabled since there is no integration between Infoblox and AWS Secrets Manager.
  name                    = "${local.name}-${random_pet.this.id}-infoblox-secret"
  recovery_window_in_days = 0 # Set to zero to force delete during Terraform destroy
  kms_key_id              = aws_kms_key.infoblox_secret.key_id
}

resource "aws_secretsmanager_secret_version" "infoblox" {
  secret_id     = aws_secretsmanager_secret.infoblox.id
  secret_string = var.infoblox_api_password
}

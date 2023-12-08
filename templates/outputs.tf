output "lambda_function_role_arn" {
  description = "ARN of the Lambda function IAM role"
  value       = module.lambda.lambda_role_arn
}

################################################################################
# Test Outputs
################################################################################

output "lambda_sqs_event_source_mapping_state" {
  description = "Required by Terratest"
  value       = module.lambda.lambda_event_source_mapping_state.sqs_ec2_events
}

output "lambda_package_s3_bucket_id" {
  description = "Required by Terratest"
  value       = module.s3_bucket_lambda_package.s3_bucket_id
}
output "lambda_s3_bucket" {
  description = "Required by Terratest"
  value       = module.lambda.s3_object.bucket
}

output "aws_signer_signing_job_signed_object_s3_key" {
  description = "Required by Terratest"
  value       = aws_signer_signing_job.lambda_package.signed_object[0].s3[0].key
}

output "lambda_s3_key" {
  description = "Required by Terratest"
  value       = module.lambda.s3_object.key
}

output "infoblox_secret" {
  description = "Required by Terratest"
  value       = aws_secretsmanager_secret.infoblox.name
}

output "lambda_environment_variables" {
  description = "Required by Terratest"
  value       = data.aws_lambda_function.dns_automation.environment[0].variables
}

output "lambda_vpc_id" {
  description = "Required by Terratest"
  value       = data.aws_vpc.lambda.id
}

output "lambda_environment_vpc_id" {
  description = "Required by Terratest"
  value       = data.aws_lambda_function.dns_automation.vpc_config[0].vpc_id
}

output "lambda_subnet_ids" {
  description = "Required by Terratest"
  value       = sort(data.aws_subnets.lambda.ids)
}

output "lambda_environment_subnet_ids" {
  description = "Required by Terratest"
  value       = sort(data.aws_lambda_function.dns_automation.vpc_config[0].subnet_ids)
}

output "lambda_security_group_id" {
  description = "Required by Terratest"
  value       = module.security_group_lambda.security_group_id
}

output "lambda_environment_security_group_id" {
  description = "Required by Terratest"
  value       = tolist(data.aws_lambda_function.dns_automation.vpc_config[0].security_group_ids)[0]
}

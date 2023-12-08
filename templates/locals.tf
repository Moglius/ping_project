locals {
  name = "dns-automation-${lower(var.environment)}"

  tags = {
    environment      = var.environment
    GitRepo          = "https://github.com/ExxonMobil/awsce-dns-automation"
    GitCommit        = substr(data.git_repository.dns_automation.commit_sha, 0, 7)
    GitTag           = data.git_repository.dns_automation.tag != null ? data.git_repository.dns_automation.tag : "none"
    dbm-app-id       = "14488"
    Application-id   = "001"
    Application-name = "dns-automation"
  }

  eventbridge_ec2_event_pattern = <<EOF
    {
        "source": ["aws.ec2", "xom.test"],
        "detail-type": ["EC2 Instance State-change Notification"],
        "detail": {
            "state": ["running", "shutting-down"]
        }
    }
    EOF

  infoblox_endpoints_ips = var.infoblox_api_ip_read == null ? [var.infoblox_api_ip] : [var.infoblox_api_ip, var.infoblox_api_ip_read]
}

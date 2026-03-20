output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web-alb.dns_name
}

output "instance_public_ips" {
  description = "Public IPs of current ASG instances"
  value       = data.aws_instances.asg_instances.public_ips
}

output "ssh_commands" {
  description = "SSH commands to connect to ASG instances"
  value       = formatlist("ssh -i %s.pem ec2-user@%s", var.key_name, data.aws_instances.asg_instances.public_ips)
}
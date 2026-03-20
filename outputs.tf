output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web-alb.dns_name
}


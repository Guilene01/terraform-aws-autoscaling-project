# Highly Available Horizontal Auto Scaling Web Application on AWS

## Overview

This project uses Terraform to deploy a highly available Apache web application on AWS across 2 Availability Zones. It uses an Auto Scaling Group to automatically scale EC2 instances based on CPU usage, and an Application Load Balancer to distribute traffic across healthy instances. The entire infrastructure is provisioned as code, making it fully reproducible with a single `terraform apply`.

---

## Architecture

The following AWS resources are provisioned by Terraform:

- **Security Group** — Controls inbound and outbound traffic. Allows HTTP (port 80) from anywhere and SSH (port 22) from a specified IP address.
- **EC2 Launch Template** — Defines the configuration for EC2 instances including AMI, instance type (t2.micro), key pair, security group, and a user data script that installs and starts Apache.
- **Target Group** — Maintains a list of healthy EC2 instances and performs HTTP health checks on `/index.html`. Used by the Load Balancer to route traffic only to healthy instances.
- **Application Load Balancer (ALB)** — Internet-facing load balancer that distributes incoming HTTP traffic across healthy instances in the Target Group.
- **Load Balancer Listener** — Listens for incoming traffic on port 80 and forwards it to the Target Group.
- **Auto Scaling Group (ASG)** — Automatically launches and terminates EC2 instances across 2 Availability Zones. Maintains a minimum of 2 instances and scales up to 4 based on CPU usage.
- **Auto Scaling Policy** — Target Tracking policy that automatically scales the ASG in and out to maintain an average CPU utilization of 50%. CloudWatch alarms are managed automatically by AWS.

### Infrastructure Diagram

```
Internet
    |
    v
Application Load Balancer
    |
    v
Load Balancer Listener (port 80)
    |
    v
Target Group (health checks)
    /         \
   v           v
EC2 (AZ-1)  EC2 (AZ-2)
      \         /
       v       v
     Auto Scaling Group
          |
          v
    CloudWatch (CPU monitoring)
          |
          v
    Scaling Policy (target 50% CPU)
```

---

## Prerequisites

Before deploying this project, make sure you have the following:

- [Terraform](https://developer.hashicorp.com/terraform/install) installed (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`)
- An AWS account with permissions to create EC2, ALB, ASG, and CloudWatch resources
- An existing EC2 Key Pair in your AWS account for SSH access

---

## Project Structure

```
project/
├── main.tf           # All AWS resources
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output values
├── terraform.tfvars  # Your variable values (do not commit to Git)
├── user_data.sh      # Apache installation script
└── README.md
```

---

## Variables

Declare the following in your `terraform.tfvars` file:

| Variable | Description | Example |
|---|---|---|
| `ami_id` | Amazon Linux 2023 AMI ID for your region | `ami-0c101f26f147fa7fd` |
| `key_pair_name` | Name of your existing EC2 Key Pair | `my-key-pair` |
| `ssh_cidr` | Your IP address in CIDR format for SSH access | `203.0.113.5/32` |

Example `terraform.tfvars`:
```hcl
ami_id        = "ami-0c101f26f147fa7fd"
key_pair_name = "my-key-pair"
ssh_cidr      = "YOUR_IP/32"
```

> **Note:** Never commit `terraform.tfvars` to version control if it contains sensitive values. Add it to `.gitignore`.

---

## Usage

**1. Clone the repository:**
```bash
git clone <your-repo-url>
cd <project-folder>
```

**2. Initialize Terraform:**
```bash
terraform init
```

**3. Create your `terraform.tfvars` file with your values.**

**4. Preview the infrastructure:**
```bash
terraform plan
```

**5. Deploy the infrastructure:**
```bash
terraform apply
```

**6. After apply, Terraform will output:**
- The ALB DNS name to access your application
- A CLI command to fetch current instance IPs

---

## Outputs

| Output | Description |
|---|---|
| `alb_dns_name` | DNS name of the Application Load Balancer — open in browser to see Apache page |
| `get_instance_ips` | AWS CLI command to fetch public IPs of current ASG instances |

Access your application:
```
http://<alb_dns_name>
```

---

## Testing

### Test 1 — Verify Apache is Running
Open the ALB DNS name in your browser. You should see:
```
AWS Auto Scaling Student Project
Server Hostname: ip-xxx-xxx-xxx-xxx.ec2.internal
```

### Test 2 — Test Auto Replacement
Terminate one instance manually in the AWS Console and watch the ASG automatically launch a replacement under EC2 → Auto Scaling Groups → Activity tab.

### Test 3 — Test CPU Scaling
SSH into an instance and run a CPU stress test:

**Get instance IPs:**
```bash
# Run the CLI command from Terraform outputs
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=web-asg" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text
```

**SSH into an instance:**
```bash
ssh -i your-key.pem ec2-user@<instance-public-ip>
```

**Install and run stress test:**
```bash
sudo yum install stress -y
stress --cpu 4 --timeout 300
```

Watch EC2 → Auto Scaling Groups → web-asg → Activity tab to see new instances launch when CPU exceeds 50%.

---

## Cleanup

To avoid unnecessary AWS charges, destroy all resources when done:

```bash
terraform destroy
```

Then manually delete your EC2 Key Pair from the AWS Console if no longer needed.

> **Important:** `terraform destroy` will terminate all instances and delete all resources created by this project.
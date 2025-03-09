# Three-Tier Web Application Deployment Infrastructure

This repository contains infrastructure-as-code (Terraform) and CI/CD pipeline (Jenkins) configuration for deploying a three-tier web application on AWS. The solution implements proper network isolation, automated deployments, and secure configuration management.

## Infrastructure Overview

**Application Components**:

- **Frontend**: React.js web interface (EC2 instance)
- **Backend**: Node.js REST API (EC2 instance)
- **Database**: MongoDB (EC2 instance with persistent storage)

**Network Architecture**:

- Default VPC with public/private subnets
- Tier-specific security groups with least-privilege rules
- SSH access restricted to bastion host/Jenkins server

## Prerequisites

1. AWS Account with IAM credentials
2. Terraform v1.5+ installed
3. Jenkins server with AWS CLI and Terraform
4. SSH key pair (`app-key.pem`) in AWS region
5. Git repository with application code

## File Structure

three-tier-app-deployment/
├── terraform/
│ ├── main.tf # Core Terraform configuration
│ ├── variables.tf # Variable definitions
│ ├── outputs.tf # Output values
│ ├── compute.tf # EC2 instances configuration
│ ├── security.tf # Security group definitions
│ ├── scripts/
│ │ ├── backend_setup.sh # Node.js installation + service config
│ │ └── frontend_setup.sh # Nginx + React app setup
│ └── terraform.tfvars # Environment variables
└── jenkins/
└── Jenkinsfile # Pipeline stages

## Terraform Configuration

### Security Groups (security.tf)

MongoDB Security Group

resource "aws_security_group" "mongodb_sg" {
ingress {
from_port = 27017
to_port = 27017
protocol = "tcp"
security_groups = [aws_security_group.backend_sg.id]
}
}

Backend Security Group

resource "aws_security_group" "backend_sg" {
ingress {
from_port = 3000
to_port = 3000
protocol = "tcp"
security_groups = [aws_security_group.frontend_sg.id]
}
}

Frontend Security Group

resource "aws_security_group" "frontend_sg" {
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
}

### EC2 Instances (compute.tf)

resource "aws_instance" "backend" {
ami = "ami-0c55b159cbfafe1f0"
instance_type = "t3.medium"
user_data = file("${path.module}/scripts/backend_setup.sh")

tags = {
Name = "backend-server"
}
}

resource "aws_instance" "frontend" {
depends_on = [aws_instance.backend]
user_data = <<-EOF
#!/bin/bash
echo "REACT_APP_API_URL=http://${aws_instance.backend.private_ip}:3000" > /src/url.js
systemctl restart nginx
EOF
}

### MongoDB Instance Configuration

resource "aws_instance" "mongodb" {
ami = "ami-0c55b159cbfafe1f0"
instance_type = "t3.medium"
user_data = file("${path.module}/scripts/mongodb_setup.sh")

tags = {
Name = "mongodb-server"
}
}

### Load Balancer (Optional)

resource "aws_elb" "frontend_elb" {
name = "frontend-elb"
subnets = [aws_subnet.public.id]
security_groups = [aws_security_group.frontend_sg.id]

listener {
instance_port = 80
instance_protocol = "http"
lb_port = 80
lb_protocol = "http"
}

instances = [aws_instance.frontend.id]
}

## Jenkins Pipeline (Jenkinsfile)

pipeline {
agent any
stages {
stage('Provision Infrastructure') {
steps {
dir('terraform') {
sh 'terraform init'
sh 'terraform apply -auto-approve'
}
}
}

    stage('Deploy Backend') {
        steps {
            sshagent(['aws-ssh-key']) {
                sh "scp -o StrictHostKeyChecking=no backend/.env ubuntu@${BACKEND_IP}:/app/"
                sh "ssh ubuntu@${BACKEND_IP} 'pm2 restart all'"
            }
        }
    }

    stage('Deploy Frontend') {
        steps {
            sshagent(['aws-ssh-key']) {
                sh "rsync -avz frontend/ ubuntu@${FRONTEND_IP}:/var/www/html/"
            }
        }
    }

    stage('Validation') {
        steps {
            sh "curl -s -o /dev/null -w '%{http_code}' ${FRONTEND_IP}:80"
            if (env.http_code != "200") {
                echo "Deployment failed"
                exit 1
            }
        }
    }

}

post {
always {
slackSend channel: '#deployments', message: "Deployment completed: ${currentBuild.result}"
}
}

## Security Implementation

1. **Secrets Management**:
   Use AWS Systems Manager (SSM) Parameter Store to securely store sensitive information like MongoDB URI and backend port.

resource "aws_ssm_parameter" "mongo_uri" {
name = "/prod/backend/MONGO_URI"
type = "SecureString"
value = "mongodb://${aws_instance.mongodb.private_ip}:27017/appdb"
}

2. **Access Controls**:

- IAM roles with least privilege
- SSH access via AWS Systems Manager Session Manager
- Automatic security group updates via Terraform

3. **Encryption**:

- EBS volumes encrypted with AWS KMS
- TLS termination at load balancer
- Secrets stored in AWS Parameter Store

## Deployment Workflow

1. **Infrastructure Provisioning**:

terraform init
terraform plan -out=tfplan
terraform apply tfplan

2. **CI/CD Pipeline Execution**:

jenkins-job-builder update pipeline.yaml
curl -X POST ${JENKINS_URL}/job/three-tier-app/build

3. **Validation**:

- Postman collection tests for API endpoints
- Lighthouse audit for frontend performance
- Security scanning with Trivy

## Maintenance Operations

**Scaling**:

- Auto Scaling Groups for frontend/backend tiers
- MongoDB replica set configuration

**Monitoring**:

- CloudWatch alarms for CPU/memory usage
- Application logging via CloudWatch Logs Agent
- Performance monitoring with Prometheus+Grafana

**Destruction**:

terraform destroy -target module.frontend
terraform destroy -target module.backend
terraform destroy -target module.database

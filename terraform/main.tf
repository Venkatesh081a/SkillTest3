provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "frontend" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.frontend_sg.name]

  user_data = file("scripts/frontend_setup.sh")

  tags = {
    Name = "venky-frontend-instance"
  }
}

resource "aws_instance" "backend" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.backend_sg.name]

  user_data = file("scripts/backend_setup.sh")

  tags = {
    Name = "venky-backend-instance"
  }
}

resource "aws_instance" "database" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.database_sg.name]

  tags = {
    Name = "venky-database-instance"
  }
}

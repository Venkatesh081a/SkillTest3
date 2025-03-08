# compute.tf
resource "aws_instance" "frontend" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  user_data              = filebase64("${path.module}/scripts/frontend_setup.sh")
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
}

resource "aws_instance" "backend" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  user_data = templatefile("${path.module}/scripts/backend_setup.sh", {
    MONGO_URI = aws_instance.mongodb.private_ip
  })
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
}

resource "aws_instance" "mongodb" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}

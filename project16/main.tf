provider "aws" {
  region = "eu-west-1"
}

terraform {



  required_providers {



    aws = { source = "hashicorp/aws", version = "~> 4.0" }



    tls = { source = "hashicorp/tls", version = "~> 4.0" }



  }



}

# 1. Data Sources (Expanded for strict syntax)



data "aws_vpc" "default" {



  default = true



}

data "aws_subnets" "default" {



  filter {



    name   = "vpc-id"



    values = [data.aws_vpc.default.id]



  }



}







data "aws_ami" "amazon_linux_2" {



  most_recent = true



  owners      = ["amazon"]



  filter {



    name   = "name"



    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]



  }



}







# 2. Self-Signed Certificate



resource "tls_private_key" "example" {



  algorithm = "RSA"



}







resource "tls_self_signed_cert" "example" {



  private_key_pem = tls_private_key.example.private_key_pem







  subject {



    common_name  = "project16.local"



    organization = "Project 16 Corp"



  }







  validity_period_hours = 24







  allowed_uses = [



    "key_encipherment",



    "digital_signature",



    "server_auth",



  ]



}







# 3. Upload Cert to IAM (Bypassing ACM permission block)



resource "aws_iam_server_certificate" "cert_legacy" {



  name             = "luffiii-project-16-cert-strict-v2"



  certificate_body = tls_self_signed_cert.example.cert_pem



  private_key      = tls_private_key.example.private_key_pem



}







# 4. Security Group (No semicolons, strict formatting)



resource "aws_security_group" "web_sg" {



  name   = "luffiii-project-16-sg"



  vpc_id = data.aws_vpc.default.id







  ingress {



    from_port   = 80



    to_port     = 80



    protocol    = "tcp"



    cidr_blocks = ["0.0.0.0/0"]



  }







  ingress {



    from_port   = 443



    to_port     = 443



    protocol    = "tcp"



    cidr_blocks = ["0.0.0.0/0"]



  }







  egress {



    from_port   = 0



    to_port     = 0



    protocol    = "-1"



    cidr_blocks = ["0.0.0.0/0"]



  }



}







# 5. EC2 Web Server



resource "aws_instance" "web" {



  ami                    = data.aws_ami.amazon_linux_2.id



  instance_type          = "t2.micro"



  vpc_security_group_ids = [aws_security_group.web_sg.id]



  subnet_id              = data.aws_subnets.default.ids[0]







  root_block_device {



    encrypted = true



  }







  user_data = <<-EOF



              #!/bin/bash



              yum install httpd -y



              echo "<h1>Welcome to Secure luffiii shushhhhhh!</h1>" > /var/www/html/index.html



              echo "OK" > /var/www/html/health.html



              systemctl start httpd



              systemctl enable httpd



              EOF







  tags = {



    Name = "luffiii-Project16-Web"



  }



}







# 6. Load Balancer & Listeners



resource "aws_lb" "secure_alb" {



  name               = "project-16-luffiii-strict"



  internal           = false



  load_balancer_type = "application"



  security_groups    = [aws_security_group.web_sg.id]



  subnets            = data.aws_subnets.default.ids



}







resource "aws_lb_target_group" "web_tg" {



  name     = "project-16-luffiii-tg-strict"



  port     = 80



  protocol = "HTTP"



  vpc_id   = data.aws_vpc.default.id







  health_check {



    path    = "/"



    matcher = "200"



  }



}







resource "aws_lb_target_group_attachment" "web_attach" {



  target_group_arn = aws_lb_target_group.web_tg.arn



  target_id        = aws_instance.web.id



  port             = 80



}







resource "aws_lb_listener" "https" {



  load_balancer_arn = aws_lb.secure_alb.arn



  port              = "443"



  protocol          = "HTTPS"



  ssl_policy        = "ELBSecurityPolicy-2016-08"



  certificate_arn   = aws_iam_server_certificate.cert_legacy.arn







  default_action {



    type             = "forward"



    target_group_arn = aws_lb_target_group.web_tg.arn



  }



}







resource "aws_lb_listener" "http_redirect" {



  load_balancer_arn = aws_lb.secure_alb.arn



  port              = "80"



  protocol          = "HTTP"







  default_action {



    type = "redirect"







    redirect {



      port        = "443"



      protocol    = "HTTPS"



      status_code = "HTTP_301"



    }



  }



}







output "alb_dns_name" {



  value = aws_lb.secure_alb.dns_name



}

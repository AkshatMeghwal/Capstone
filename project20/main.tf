# 1. Provider



provider "aws" {



  region = "eu-west-1"



}







# 2. DATA SOURCES: Automatically fetch environment info



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







# 3. Security Group for ALB



resource "aws_security_group" "alb_sg" {



  name        = "luffiii-project-20-alb-sg"



  vpc_id      = data.aws_vpc.default.id







  ingress {



    from_port   = 80



    to_port     = 80



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







# 4. Security Group for EC2



resource "aws_security_group" "ec2_sg" {



  name   = "luffiii-project-20-ec2-sg"



  vpc_id = data.aws_vpc.default.id







  ingress {



    from_port       = 80



    to_port         = 80



    protocol        = "tcp"



    security_groups = [aws_security_group.alb_sg.id]



  }







  egress {



    from_port   = 0



    to_port     = 0



    protocol    = "-1"



    cidr_blocks = ["0.0.0.0/0"]



  }



}







# 5. Application Load Balancer



resource "aws_lb" "project_alb" {



  name               = "luffiii-project-20-alb"



  internal           = false



  load_balancer_type = "application"



  security_groups    = [aws_security_group.alb_sg.id]



  subnets            = data.aws_subnets.default.ids # Uses all default subnets



}







# 6. Target Group with Health Checks



resource "aws_lb_target_group" "app_tg" {



  name     = "luffiii-project-20-tg"



  port     = 80



  protocol = "HTTP"



  vpc_id   = data.aws_vpc.default.id







  health_check {



    path                = "/"



    interval            = 30



    timeout             = 5



    healthy_threshold   = 3



    unhealthy_threshold = 2



    matcher             = "200"



  }



}







# 7. ALB Listener



resource "aws_lb_listener" "http" {



  load_balancer_arn = aws_lb.project_alb.arn



  port              = "80"



  protocol          = "HTTP"







  default_action {



    type             = "forward"



    target_group_arn = aws_lb_target_group.app_tg.arn



  }



}







# 8. EC2 Instances (2 total)



resource "aws_instance" "web_server" {



  count                  = 2



  ami                    = data.aws_ami.amazon_linux_2.id



  instance_type          = "t2.micro"



  vpc_security_group_ids = [aws_security_group.ec2_sg.id]



  subnet_id              = data.aws_subnets.default.ids[count.index] # Spreads them across subnets



# ADD THIS BLOCK TO COMPLY WITH ENCRYPTION POLICIES

  root_block_device {

    encrypted   = true

    volume_type = "gp3" # gp3 is usually preferred over gp2

  }



  user_data = <<-EOF



              #!/bin/bash



              yum update -y



              yum install -y httpd



              systemctl start httpd



              systemctl enable httpd



              echo "<h1>Project 20: Load Balanced Server $(hostname -f)</h1>" > /var/www/html/index.html



              EOF







  tags = {



    Name = "Project20-Instance-${count.index + 1}"



  }



}







# 9. Register Instances with Target Group



resource "aws_lb_target_group_attachment" "tg_attachment" {



  count            = 2



  target_group_arn = aws_lb_target_group.app_tg.arn



  target_id        = aws_instance.web_server[count.index].id



  port             = 80



}







# OUTPUTS



output "alb_dns_link" {



  description = "Copy and paste this URL into your browser"



  value       = "http://${aws_lb.project_alb.dns_name}"



}

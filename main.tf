# 1. Provider



provider "aws" {



  region = "eu-west-1"



}







# 2. Data Sources (Lookup VPC, Subnets, and AMI)



data "aws_vpc" "default" {



  default = true



}







data "aws_subnets" "default" {



  filter {



    name   = "vpc-id"



    values = [data.aws_vpc.default.id]



  }



}







data "aws_ami" "amazon_linux" {



  most_recent = true



  owners      = ["amazon"]



  filter {



    name   = "name"



    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]



  }



}







# 3. Security Group



resource "aws_security_group" "p3_sg" {



  name        = "some-moitoring-sg"



  description = "Allow SSH and outbound traffic"



  vpc_id      = data.aws_vpc.default.id







  ingress {



    from_port   = 22



    to_port     = 22



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







# 4. EC2 Instance (The "Target")



resource "aws_instance" "p3_server" {



  ami                    = data.aws_ami.amazon_linux.id



  instance_type          = "t2.micro"



  vpc_security_group_ids = [aws_security_group.p3_sg.id]



  subnet_id              = data.aws_subnets.default.ids[0]







  root_block_device {



    encrypted = true



  }







  # This script runs ONCE at boot to install tools and spike CPU



  user_data = <<-EOF



              #!/bin/bash



              amazon-linux-extras install epel -y



              yum install stress-ng -y



              



              # WAIT ONLY 10 SECONDS (INSTANT SPIKE)



              sleep 10



              



              # Run stress test for 10 minutes (600 seconds)



              stress-ng --cpu 1 --cpu-load 100 --timeout 600



              EOF







  tags = {



    Name = "Project3-Instance"



  }



}







# 5. CloudWatch Alarm (The "Monitor")



resource "aws_cloudwatch_metric_alarm" "p3_alarm" {



  alarm_name          = "P3-High-CPU-Alert"



  comparison_operator = "GreaterThanThreshold"



  evaluation_periods  = "1"



  metric_name         = "CPUUtilization"



  namespace           = "AWS/EC2"



  period              = "60"



  statistic           = "Average"



  threshold           = "70"



  alarm_description   = "Monitor Project 3 EC2 CPU spikes"







  dimensions = {



    InstanceId = aws_instance.p3_server.id



  }



}







# 6. Output



output "project4_instance_id" {



  value = aws_instance.p3_server.id



}

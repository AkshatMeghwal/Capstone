################################### DATA ###############################################



data "aws_availability_zones" "available" {}







# Force x86_64 Amazon Linux 2 AMI to match t2.micro



data "aws_ami" "aws_linux2_x86" {



  most_recent = true



  owners      = ["amazon"]







  filter {



    name   = "name"



    values = ["amzn2-ami-hvm-*-x86_64-gp2"]



  }







  filter {



    name   = "root-device-type"



    values = ["ebs"]



  }







  filter {



    name   = "virtualization-type"



    values = ["hvm"]



  }







  filter {



    name   = "architecture"



    values = ["x86_64"]



  }



}







################################### NETWORKING #########################################



resource "aws_vpc" "vpc" {



  cidr_block           = var.network_address_space



  enable_dns_support   = true



  enable_dns_hostnames = true







  tags = {



    Name = "tf-web-vpc"



  }



}







resource "aws_internet_gateway" "igw" {



  vpc_id = aws_vpc.vpc.id







  tags = {



    Name = "tf-web-igw"



  }



}







resource "aws_subnet" "subnet" {



  count                   = var.subnet_count



  vpc_id                  = aws_vpc.vpc.id



  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index)



  map_public_ip_on_launch = true



  availability_zone       = data.aws_availability_zones.available.names[count.index]







  tags = {



    Name = "tf-web-subnet-${count.index}"



  }



}







resource "aws_route_table" "rtb" {



  vpc_id = aws_vpc.vpc.id







  route {



    cidr_block = "0.0.0.0/0"



    gateway_id = aws_internet_gateway.igw.id



  }







  tags = {



    Name = "tf-web-public-rt"



  }



}







resource "aws_route_table_association" "rta-subnet" {



  count          = var.subnet_count



  subnet_id      = aws_subnet.subnet[count.index].id



  route_table_id = aws_route_table.rtb.id



}







################################### SECURITY GROUP #####################################



resource "aws_security_group" "web_sg" {



  name        = "web-sg-"



  description = "Allow SSH from your IP and HTTP from internet"



  vpc_id      = aws_vpc.vpc.id







  # SSH - restrict to your IP



  ingress {



    description = "SSH from your IP"



    from_port   = 22



    to_port     = 22



    protocol    = "tcp"



    cidr_blocks = ["223.186.153.90/32"]



  }







  # HTTP - open to world



  ingress {



    description = "HTTP from anywhere"



    from_port   = 80



    to_port     = 80



    protocol    = "tcp"



    cidr_blocks = ["0.0.0.0/0"]



  }







  # Egress - allow updates/install



  egress {



    description = "Allow all outbound"



    from_port   = 0



    to_port     = 0



    protocol    = "-1"



    cidr_blocks = ["0.0.0.0/0"]



  }







  tags = {



    Name = "web-sg"



  }



}







################################### COMPUTE ############################################



resource "aws_instance" "myinstance" {



  count                  = var.instance_count



  ami                    = data.aws_ami.aws_linux2_x86.id



  instance_type          = "t2.micro"



  subnet_id              = aws_subnet.subnet[count.index % var.subnet_count].id



  vpc_security_group_ids = [aws_security_group.web_sg.id]



  key_name               = var.key_name







  root_block_device {



    encrypted   = true



    volume_size = 8



  }







  # NGINX user_data — escape ${HOSTNAME} as $${HOSTNAME} so bash expands it on the instance



  user_data = <<-EOF



    #!/bin/bash



    set -eux



    yum update -y



    amazon-linux-extras enable nginx1



    yum install -y nginx



    systemctl enable nginx







    cat >/usr/share/nginx/html/index.html <<'EOPAGE'



    <!doctype html>



    <html>



      <head>



        <meta charset="utf-8"/>



        <title>Pirate King Server</title>

      </head>



      <body>



        <h1>It works! </h1>



        <p>Luffiii became pirate king.... yayyy</p>



      </body>



    </html>



    EOPAGE







    systemctl start nginx



  EOF







  tags = {



    Name      = "Terraform-${count.index + 1}"



    Role      = "web"



    ManagedBy = "terraform"



  }



}







################################### OUTPUTS ############################################



output "aws_host_ip" {



  description = "Private IPs"



  value       = aws_instance.myinstance[*].private_ip



}







output "aws_public_dns" {



  description = "Public DNS names"



  value       = aws_instance.myinstance[*].public_dns



}







output "web_instance_public_ips" {



  description = "Public IPs of web instances"



  value       = aws_instance.myinstance[*].public_ip



}







output "web_urls" {



  description = "HTTP URLs to test in a browser"



  value       = [for ip in aws_instance.myinstance[*].public_ip : "http://${ip}"]



}




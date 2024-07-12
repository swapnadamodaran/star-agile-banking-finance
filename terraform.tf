
# Select region
provider "aws" {
  region     = "us-east-1"
}
# Create VPC
resource "aws_vpc" "sdvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "sdvpc"
  }
}
# Create Subnet
resource "aws_subnet" "sdsubnet" {
  vpc_id     = aws_vpc.sdvpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "sdsubnet"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "sdgw" {
  vpc_id = aws_vpc.sdvpc.id
  tags = {
    Name = "sdgw"
  }
}
# Route Table
resource "aws_route_table" "sdrt" {
  vpc_id = aws_vpc.sdvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sdgw.id
  }
  tags = {
    Name = "sdrt"
  }
}
# Route Table Association
resource "aws_route_table_association" "sdrta" {
  subnet_id      = aws_subnet.sdsubnet.id
  route_table_id = aws_route_table.sdrt.id
}
# Security Groups
resource "aws_security_group" "sdsg" {
  name        = "sdsg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.sdvpc.id
 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }

  tags = {
    Name = "sdsg"
  }
}
# Creating a new network interface
resource "aws_network_interface" "ni" {
 subnet_id = aws_subnet.sdsubnet.id
 private_ips = ["10.0.1.10"]
 security_groups = [aws_security_group.sdsg.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "eip" {
 vpc = true
 network_interface = aws_network_interface.ni.id
 associate_with_private_ip = "10.0.1.10"
}



# Create Instance
resource "aws_instance" "testserver" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  key_name = "valid"
network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.ni.id
 }
user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update -y
EOF

tags = {
    Name = "Test_server"
  }
}

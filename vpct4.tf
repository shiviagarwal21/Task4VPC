provider "aws" {
  region = "ap-south-1"
  profile = "shivi"
}


resource "aws_vpc" "vpc_task4" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_support="true"
  enable_dns_hostnames="true"
  instance_tenancy = "default"

  tags = {
    Name = "vpc_task"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id     =  aws_vpc.vpc_task4.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id     =  aws_vpc.vpc_task4.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_eip" "elastic_ip"{
  vpc = true
}


resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id = aws_subnet.publicsubnet.id
  
  tags = {
    Name = "Natgateway"
  }
}

resource "aws_internet_gateway" "internetgateway" {
  vpc_id =  aws_vpc.vpc_task4.id

  tags = {
    Name = "Internet_gateway"
  }
}

resource "aws_route_table" "internet_gateway_route_table" {
  vpc_id =  aws_vpc.vpc_task4.id
  
  tags = {
    Name = "internet_gateway_rt"
  }
}

resource "aws_route" "route1" {
  route_table_id            =  aws_route_table.internet_gateway_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_internet_gateway.internetgateway.id
  
}

resource "aws_route_table_association" "route_table_assoc1" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.internet_gateway_route_table.id
}

resource "aws_route_table" "nat_gateway_route_table" {
  vpc_id =  aws_vpc.vpc_task4.id
  
  tags = {
    Name = "nat_gateway_rt"
  }
}

resource "aws_route" "route2" {
  route_table_id            =   aws_route_table.nat_gateway_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_nat_gateway.nat_gateway.id
  
}

resource "aws_route_table_association" "route_table_assoc2" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.nat_gateway_route_table.id
}

resource "tls_private_key" "task3_key" { 
  algorithm = "RSA"
}

resource "aws_key_pair" "task3_key" {
key_name = "task3_key"
public_key= tls_private_key.task3_key.public_key_openssh
}


resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress"
  description = "allow ssh and http"
  vpc_id = aws_vpc.vpc_task4.id

ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

tags = {
    Name = "wordpress"
  }
}



resource "aws_security_group" "mysql_sg" {
  name        = "mysql"
  description = "Allow MYSQL"
  vpc_id      =   aws_vpc.vpc_task4.id


  ingress {
    description = "MYSQL/Aurora"
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.wordpress_sg.id ]
  }
   
   ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.wordpress_sg.id ]
  }
 
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
    Name = "mysql"
  }

}


resource "aws_instance" "wordpress" {
  ami                  = "ami-000cbce3e1b899ebd"
  instance_type  = "t2.micro"
  key_name        = "keycloudclass"
  security_groups =  [aws_security_group.wordpress_sg.id]  
  subnet_id =  aws_subnet.publicsubnet.id
  
  tags = {
    Name = "wp_os"
  }
}

resource "aws_instance" "mysql" {
  ami                  = "ami-08706cb5f68222d09"
  instance_type  = "t2.micro"
  key_name        = "keycloudclass"
  security_groups =  [aws_security_group.mysql_sg.id]  
  subnet_id =  aws_subnet.privatesubnet.id

  tags = {
    Name = "mysql_os"
  }

}





















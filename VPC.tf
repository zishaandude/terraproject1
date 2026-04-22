# VPC

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  vailability_zone = "us-east-1a"
  tags = {
    Name = "public_1a"
  }
}


resource "aws_subnet" "public_1b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  vailability_zone = "us-east-1b"
  tags = {
    Name = "public_1b"
  }
}

resource "aws_subnet" "private_2a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  vailability_zone = "us-east-1a"
  tags = {
    Name = "private_2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  vailability_zone = "us-east-1b"
  tags = {
    Name = "public_2b"
  }
}

resource "aws_subnet" "private_3a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  vailability_zone = "us-east-1a"
  tags = {
    Name = "private_3a"
  }
}

resource "aws_subnet" "private_3b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  vailability_zone = "us-east-1b"
  tags = {
    Name = "private_3b"
  }
}

# INTERNET GATWAY

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# NAT GATWAY

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "nat-gateway"
  }
}


# ROUTE TABLE

resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

esource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_3a" {
  subnet_id      = aws_subnet.private_3a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_3b" {
  subnet_id      = aws_subnet.private_3b.id
  route_table_id = aws_route_table.private.id
}

# Security Group

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  name   = "web-sg"

  # HTTP for Web Servers
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for Admin
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# MySQL for RDS
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Option 1: allow all (not secure in prod)
    # cidr_blocks = ["0.0.0.0/0"]

    # Option 2 (recommended): allow only within VPC
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

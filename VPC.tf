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
  cidr_block = "10.0.1.0/24"
  vailability_zone = "us-east-1a"
  tags = {
    Name = "private_2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  vailability_zone = "us-east-1b"
  tags = {
    Name = "public_2b"
  }
}

resource "aws_subnet" "private_3a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  vailability_zone = "us-east-1a"
  tags = {
    Name = "private_3a"
  }
}

resource "aws_subnet" "private_3b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  vailability_zone = "us-east-1b"
  tags = {
    Name = "private_3b"
  }
}

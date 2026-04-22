# =========================
# AWS PROVIDER CONFIG
# =========================
provider "aws" {
  region = "ap-south-1"   # Mumbai region
}

# =========================
# VPC (Virtual Private Cloud)
# =========================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"  # Large private network
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# =========================
# PUBLIC SUBNETS (for ALB + EC2)
# =========================
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"   # AZ 1

  tags = {
    Name = "public-1a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"   # AZ 2

  tags = {
    Name = "public-1b"
  }
}

# =========================
# PRIVATE SUBNETS (for DB)
# =========================
resource "aws_subnet" "private_2a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-2b"
  }
}

# =========================
# INTERNET GATEWAY
# =========================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# =========================
# NAT GATEWAY (for private subnet internet access)
# =========================
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gateway"
  }
}

# =========================
# ROUTE TABLE - PUBLIC
# =========================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate public subnets
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# =========================
# ROUTE TABLE - PRIVATE
# =========================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2b" {
  subnet_id      = aws_subnet.private_2b.id
  route_table_id = aws_route_table.private.id
}

# =========================
# SECURITY GROUP
# =========================
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (⚠ better restrict to your IP in real use)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================
# LAUNCH TEMPLATE (EC2 config)
# =========================
resource "aws_launch_template" "public_web_lt" {
  name_prefix   = "public-web-"
  image_id      = "ami-0e12ffc2dd465f6e4"  # your AMI
  instance_type = "t3.micro"              # free tier eligible sometimes

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Install Apache on boot
  user_data = base64encode(<<-EOF
#!/bin/bash
apt update -y
apt install -y apache2
systemctl enable apache2
systemctl start apache2
echo "Hello from Terraform EC2" > /var/www/html/index.html
EOF
  )
}

# =========================
# APPLICATION LOAD BALANCER
# =========================
resource "aws_lb" "public_alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.web_sg.id]

  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id
  ]
}

# Target Group for EC2
resource "aws_lb_target_group" "public_tg" {
  name     = "public-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Listener (connect ALB to TG)
resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

# =========================
# AUTO SCALING GROUP
# =========================
resource "aws_autoscaling_group" "public_asg" {
  name             = "public-asg"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id
  ]

  target_group_arns = [aws_lb_target_group.public_tg.arn]

  launch_template {
    id      = aws_launch_template.public_web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "public-ec2"
    propagate_at_launch = true
  }
}

# =========================
# RDS SUBNET GROUP
# =========================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds-subnet-group"

  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2b.id
  ]

  tags = {
    Name = "rds-subnet-group"
  }
}

# =========================
# RDS DATABASE (MySQL)
# =========================
resource "aws_db_instance" "mydb" {
  identifier        = "mydb-instance"
  allocated_storage = 20

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  username = "admin"
  password = "MySecurePass123!"  # change later

  db_name              = "mydb"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  skip_final_snapshot = true
  multi_az            = false

  publicly_accessible = false  # secure DB (important)
}s
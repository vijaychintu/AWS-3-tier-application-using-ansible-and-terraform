terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name}-igw" }
}

# 2 AZs
data "aws_availability_zones" "available" {}

# Public subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}
#assign an elastic ip (ELP)
resource "aws_eip" "app_ip" {
  instance = aws_instance.app.id
  vpc      = true
}


# Private subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.name}-private-${count.index}" }
}

# NAT GW for private subnets
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "${var.name}-nat" }
  depends_on = [aws_internet_gateway.igw]
}

# Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

  tags = { Name = "${var.name}-rt-public" }
}
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
  cidr_block     = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

  tags = { Name = "${var.name}-rt-private" }
}
resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Security groups ---
# ALB SG - allow HTTP from world, to EC2 HTTP
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.main.id
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

  tags = { Name = "${var.name}-alb-sg" }
}


resource "aws_security_group" "app_sg" {
  name        = "my-app-security-group"
  description = "My application security group"
  vpc_id      = "vpc-001e60abc5f89f1fc" # You can hardcode the ID or use a variable

  # Inbound rule for SSH (Port 22)
  # This allows you to SSH into the instance to troubleshoot
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be more restrictive in production
  }

  # Inbound rule for HTTP (Port 80)
  # This is the crucial rule that allows web traffic to your Nginx server
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule
  # Allows the instance to make external requests (e.g., for 'apt-get update')
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-app-sg"
  }
}




# EC2 SG - allow 80 only from ALB, allow SSM endpoint
resource "aws_security_group" "ec2_sg" {
  name        = "${var.name}-ec2-sg"
  description = "EC2 SG"
  vpc_id      = aws_vpc.main.id

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

  tags = { Name = "${var.name}-ec2-sg" }
}

# (Optional) RDS SG - allow Postgres from EC2 SG only
resource "aws_security_group" "rds_sg" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.name}-rds-sg"
  description = "RDS SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = { Name = "${var.name}-rds-sg" }
}

# --- ALB ---
resource "aws_lb" "app" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
  path                = "/"
  port                = "traffic-port"
  healthy_threshold   = 2
  unhealthy_threshold = 5
}

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
  type             = "forward"
  target_group_arn = aws_lb_target_group.tg.arn
}

}

# --- IAM for EC2 (SSM + CW) ---
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
   principals {
  type        = "Service"
  identifiers = ["ec2.amazonaws.com"]
}

  }
}
resource "aws_iam_role" "ec2_role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- Launch template + ASG ---
data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
  name   = "name"
  values = ["al2023-ami-*-x86_64"]
}

}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.linux.id
  instance_type = var.instance_type
  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = filebase64("${path.module}/userdata.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-app"
      Role = "app"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id]
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
  lifecycle { create_before_destroy = true }
}

# --- (Optional) RDS ---
resource "aws_db_subnet_group" "rds" {
  count      = var.enable_rds ? 1 : 0
  name       = "${var.name}-rds-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_db_instance" "postgres" {
  count                        = var.enable_rds ? 1 : 0
  identifier                   = "${var.name}-pg"
  engine                       = "postgres"
  engine_version               = "16.3"
  instance_class               = "db.t4g.micro"
  allocated_storage            = 20
  username                     = var.db_username
  password                     = var.db_password
  db_subnet_group_name         = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids       = [aws_security_group.rds_sg[0].id]
  publicly_accessible          = false
  skip_final_snapshot          = true
  deletion_protection          = false
}

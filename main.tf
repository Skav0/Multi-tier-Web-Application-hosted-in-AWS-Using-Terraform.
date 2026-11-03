terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}


################ASG#########################
resource "aws_launch_template" "example" {
  name_prefix   = "example"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
}

resource "aws_autoscaling_group" "example" {
  capacity_rebalance  = true
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.example.id
      }

    }
  }
}

#################################









#######ALB##############
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1, aws_subnet.public_2]

  enable_deletion_protection = true

  tags = {
    name = "ALB"
    Environment = "production"
  }
}

########################


# AMI Data Source for Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#*********************Security Groups*********************************8
# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for internet-facing Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP (Port 80) from anywhere
  ingress {
    description      = "Allow HTTP from public internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  # Outbound traffic to the backend Security Group (Port 8080)
  egress {
    description     = "Allow traffic to backend instances"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = {
    Name        = "alb-sg"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Backend Security Group
resource "aws_security_group" "backend" {
  name        = "instances-sg"
  description = "Security group for backend instances"
  vpc_id      = aws_vpc.main.id

  #ingress rule made for the incoming traffic from the ALB on port 8080/tcp.
ingress {
  description     = "Allow traffic from ALB only"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id] # SG Chaining
}

  # Allow outbound internet traffic (via NAT Gateway for package updates)
  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "instances-sg"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

#*****************Backend Instance 1 (Private Subnet 1 / AZ us-east-1a***********************
resource "aws_instance" "backend_1" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.backend.id]

  tags = {
    Name        = "Web_Server1"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

#*****************Backend Instance 2 (Private Subnet 2 / AZ us-east-1b)
resource "aws_instance" "backend_2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.backend.id]

  tags = {
    Name        = "Web_server2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
#**********************************************************************************************



#*****************below are the subnets**********
# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public_Subnet1"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public_Subnet2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.100.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "Private_Subnet1"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.200.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "Private_Subnet2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

#**********************************************








#************aws_internet_gateway*****************

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}



#************aws_eip*****************
resource "aws_eip" "lb1" {
  
}


#######################################
resource "aws_eip" "lb2" {
  
}
#*****************************
#************aws_nat_gateway*****************

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.lb1.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "NAT GWA"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}
#######################################
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.lb2.id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name = "NAT GWB"
  }

  depends_on = [aws_internet_gateway.main]
}


#*****************************



#########below are the route tables+association to subnets##########
#*****************************
# Subnet to Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}
#******************************************************
# Public Route Table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "Public RT"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


# Private Route Table 1
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name        = "Private RT_1"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Private Route Table 2
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name        = "Private RT_2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
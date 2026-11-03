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
  subnet_id     = aws_subnet.example.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}
#######################################
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.lb2.id
  subnet_id     = aws_subnet.example.id

  tags = {
    Name = "gw NAT"
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
# Public Route Table 1
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
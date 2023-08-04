provider "aws" {
  region = "us-east-1"
}

// Create VPC
resource "aws_vpc" "customer_management_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "customer_management_vpc"
  }
}

// Define public subnets
resource "aws_subnet" "customer-management-public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id            = aws_vpc.customer_management_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  
  tags = {
    Name = "customer-management-public-${element(["1a", "2b", "3a"], count.index)}"
  }
}

// Define private db subnets
resource "aws_subnet" "customer-management-private-db" {
  count = length(var.private_db_subnet_cidr_blocks)

  vpc_id            = aws_vpc.customer_management_vpc.id
  cidr_block        = var.private_db_subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  
  tags = {
    Name = "customer-management-private-db-${element(["1a", "2b", "3a"], count.index)}"
  }
}

// Define private RS subnets
resource "aws_subnet" "customer-management-private-rs" {
  count = length(var.private_rs_subnet_cidr_blocks)

  vpc_id            = aws_vpc.customer_management_vpc.id
  cidr_block        = var.private_rs_subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  
  tags = {
    Name = "customer-management-private-rs-${element(["1a", "2b", "3c"], count.index)}"
  }
}

resource "aws_internet_gateway" "customer-management-igw" {
  vpc_id = aws_vpc.customer_management_vpc.id

  tags = {
    Name = "customer-management-igw"
  }
}


resource "aws_route_table" "customer-management-public-rt" {
  vpc_id = aws_vpc.customer_management_vpc.id

  route {
    // Associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    // CRT uses this IGW to reach the internet
    gateway_id = aws_internet_gateway.customer-management-igw.id
  }

  tags = {
    Name = "customer-management-public-rt"
  }
}

// Associate public subnets with the route table
resource "aws_route_table_association" "customer-management-public-subnet-association" {
  count          = length(aws_subnet.customer-management-public)
  subnet_id      = aws_subnet.customer-management-public[count.index].id
  route_table_id = aws_route_table.customer-management-public-rt.id
}

// Creating an Elastic IP for the NAT Gateway!
resource "aws_eip" "customer-management-nat-gateway-eip" {
  vpc = true
}

resource "aws_nat_gateway" "customer-management-nat-gateway" {
  allocation_id = aws_eip.customer-management-nat-gateway-eip.id
  subnet_id     = aws_subnet.customer-management-public[0].id  // Assuming you want to use the first public subnet (1a)

  tags = {
    Name = "customer-management-nat-gw"
  }
}

resource "aws_route_table" "customer-management-private-db-rt" {
  vpc_id = aws_vpc.customer_management_vpc.id

  route {
    // Associated subnet can reach everywhere
    cidr_block     = "0.0.0.0/0"
    // CRT uses this NAT Gateway to reach the internet
    nat_gateway_id = aws_nat_gateway.customer-management-nat-gateway.id
  }

  tags = {
    Name = "customer-management-private-db-rt"
  }
}

// Associate private DB subnets with the route table
resource "aws_route_table_association" "customer-management-private-db-subnet-association" {
  count          = length(aws_subnet.customer-management-private-db)
  subnet_id      = aws_subnet.customer-management-private-db[count.index].id
  route_table_id = aws_route_table.customer-management-private-db-rt.id
}

resource "aws_route_table" "customer-management-private-rs-rt" {
  vpc_id = aws_vpc.customer_management_vpc.id

  route {
    // Associated subnet can reach everywhere
    cidr_block     = "0.0.0.0/0"
    // CRT uses this NAT Gateway to reach the internet
    nat_gateway_id = aws_nat_gateway.customer-management-nat-gateway.id
  }

  tags = {
    Name = "customer-management-private-rs-rt"
  }
}

// Associate private RS subnets with the route table
resource "aws_route_table_association" "customer-management-private-rs-subnet-association" {
  count          = length(aws_subnet.customer-management-private-rs)
  subnet_id      = aws_subnet.customer-management-private-rs[count.index].id
  route_table_id = aws_route_table.customer-management-private-rs-rt.id
}



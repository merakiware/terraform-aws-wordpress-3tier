resource "aws_vpc" "wpdv2-vpc" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wpdv2-vpc"
  }
}

# Creating public & private subnets

resource "aws_subnet" "public" {
  count = 3
  vpc_id = aws_vpc.wpdv2-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project}-public-subnet-${count.index + 1}"
    Project = var.project
  }
  
}

resource "aws_subnet" "private_sub" {
  count = 3
  vpc_id = aws_vpc.wpdv2-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 8) # We're starting at the 9th subnet because we put +8
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project}-private-subnet-${count.index + 1}"
    Project = var.project
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "wpdv2-igw" {
  vpc_id = aws_vpc.wpdv2-vpc.id

  tags = {
    Name = "${var.project}-IGw"
  }
  
}
# Creating EIP for NAT
resource "aws_eip" "natt" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-nat-eip"
  }

  depends_on = [ aws_internet_gateway.wpdv2-igw ]
}


# Creating NAT Gateway
resource "aws_nat_gateway" "NAT-Gateway-wpdv2" {
  allocation_id = aws_eip.natt.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-nat-gateway"
  }
  
  depends_on = [aws_internet_gateway.wpdv2-igw]

}

# Creating a public route table
resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.wpdv2-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wpdv2-igw.id
  }
  
  tags = {
    Name = "${var.project}-public-rt"
  }
}

# Creating private route table
resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.wpdv2-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-Gateway-wpdv2.id
  }
  tags = {
    Name = "${var.project}-private-rt"
  }
}
# Connecting public subnets to the public route table
resource "aws_route_table_association" "public_table_association" {
  count = 3
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_table.id


}


resource "aws_route_table_association" "private_table_association" {
  count = 3
  subnet_id = aws_subnet.private_sub[count.index].id
  route_table_id = aws_route_table.private_table.id
  
}



provider "aws" {
  region = "us-east-1" # replace with your desired region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # replace with your desired CIDR block
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.5.0/24" # replace with your desired CIDR block
}

resource "aws_security_group" "my_security_group" {
  name_prefix = "my_security_group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }
}

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}


# configuration for EKS cluster
# Define the EKS cluster resource
resource "aws_eks_cluster" "my_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids = [
      aws_subnet.private-subnet1.id,
      aws_subnet.private-subnet2.id
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

# Define the IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required IAM policy to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# Create private subnets for the EKS cluster
resource "aws_subnet" "private-subnet1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-private-subnet-2"
  }
}

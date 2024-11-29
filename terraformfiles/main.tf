#Step 1: Creating the private key
resource "tls_private_key" "cicd-key" {
  algorithm = "RSA"
  rsa_bits = 2048
}
#Step 2: Name the pem key
resource "aws_key_pair" "cicd-key-pair" {
  key_name = "cicd_key"
  public_key = tls_private_key.cicd-key.public_key_openssh
}
#Step 3: Create the file and save the file in the folder
resource "local_file" "cicd-key-file" {
  content = tls_private_key.cicd-key.private_key_pem
  filename = "${path.module}/mykey/cicd_key.pem"
  file_permission = 0400
}

#Step5: Datasourcing the data from default VPC rules
# data "aws_vpc" "defaultvpc" {
    # default = true
# }

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Step 7: Create a Route Table and associate it with the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Step 6: Create Security group
resource "aws_security_group" "cicd-sg" {
  name = "allow-ssh"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Step 4: Create the ec2 instance
resource "aws_instance" "cicd-ec2" {
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  vpc_security_group_ids = [ aws_security_group.cicd-sg.id ]
  tags = {
    name = "cicd-ec2"
  }

  key_name = aws_key_pair.cicd-key-pair.key_name
}

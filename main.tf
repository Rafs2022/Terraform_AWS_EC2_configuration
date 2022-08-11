resource "aws_vpc" "raf_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "dev"
  }
}

resource "aws_subnet" "raf_public_subnet" {
  vpc_id                  = aws_vpc.raf_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    name = "public"

  }
}

resource "aws_internet_gateway" "raf_internet_gateway" {
  vpc_id = aws_vpc.raf_vpc.id

  tags = {
    name = "raf-igw"
  }
}

resource "aws_route_table" "raf_public_rt" {
  vpc_id = aws_vpc.raf_vpc.id

  tags = {
    "name" = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.raf_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.raf_internet_gateway.id
}

resource "aws_route_table_association" "raf_public_access" {
  subnet_id      = aws_subnet.raf_public_subnet.id
  route_table_id = aws_route_table.raf_public_rt.id
}

resource "aws_security_group" "raf_scg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.raf_vpc.id

  ingress {
    cidr_blocks = ["152.231.0.0/16"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "rafauth" {
  key_name   = "rafkey"
  public_key = file("~/.ssh/rafkey.pub")
}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.rafauth.id
  vpc_security_group_ids = [aws_security_group.raf_scg.id]
  subnet_id              = aws_subnet.raf_public_subnet.id
  user_data              = file("userdata.tpl")

  tags = {
    "name" = "dev-node"
  }
}

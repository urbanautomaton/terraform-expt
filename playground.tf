variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "eu-west-1"
}

resource "aws_vpc" "fltest" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "fltest"
  }
}

resource "aws_internet_gateway" "fltest-gw" {
  vpc_id = "${aws_vpc.fltest.id}"

  tags {
    Name = "fltest-gw"
  }
}

resource "aws_subnet" "fltest-pub-a" {
  vpc_id                  = "${aws_vpc.fltest.id}"
  availability_zone       = "eu-west-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "fltest-pub-a"
  }
}

resource "aws_route_table" "fltest-pub-a" {
  vpc_id = "${aws_vpc.fltest.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.fltest-gw.id}"
  }
  tags {
    Name = "fltest-pub"
  }
}

resource "aws_route_table_association" "fltest-pub-a" {
  subnet_id = "${aws_subnet.fltest-pub-a.id}"
  route_table_id = "${aws_route_table.fltest-pub-a.id}"
}

resource "aws_instance" "fltest-nat-01a" {
  # amzn-ami-vpc-nat-hvm-2014.09.1.x86_64-gp2
  ami = "ami-14913f63"
  availability_zone = "a"
  subnet_id = "${aws_subnet.fltest-pub-a.id}"
  instance_type = "t1.micro"
  associate_public_ip_address = true
  # Allow traffic not destined for the NAT to be routed to it
  source_dest_check = false

  tags {
    Name = "fltest-nat-01a"
  }
}

resource "aws_subnet" "fltest-int-a" {
  vpc_id            = "${aws_vpc.fltest.id}"
  availability_zone = "eu-west-1a"
  cidr_block        = "10.0.10.0/24"

  tags {
    Name = "fltest-int-a"
  }
}

resource "aws_route_table" "fltest-int-a" {
  vpc_id = "${aws_vpc.fltest.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_instance.fltest-nat-01a.id}"
  }
  tags {
    Name = "fltest-int"
  }
}

resource "aws_route_table_association" "fltest-int-a" {
  subnet_id = "${aws_subnet.fltest-int-a.id}"
  route_table_id = "${aws_route_table.fltest-int-a.id}"
}

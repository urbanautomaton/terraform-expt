provider "aws" {
  access_key = "nope"
  secret_key = "nope"
  region     = "eu-west-1"
}

resource "aws_vpc" "test-1" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "test-1"
  }
}

resource "aws_internet_gateway" "test-1-gw" {
  vpc_id = "${aws_vpc.test-1.id}"

  tags {
    Name = "test-1-gw"
  }
}

resource "aws_subnet" "test-1a-pub" {
  vpc_id                  = "${aws_vpc.test-1.id}"
  availability_zone       = "eu-west-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "test-1a-pub"
  }
}

resource "aws_route_table" "test-1-pub" {
  vpc_id = "${aws_vpc.test-1.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-1-gw.id}"
  }
  tags {
    Name = "test-1-pub"
  }
}

resource "aws_route_table_association" "test-1-pub" {
  subnet_id = "${aws_subnet.test-1a-pub.id}"
  route_table_id = "${aws_route_table.test-1-pub.id}"
}

resource "aws_route_table" "test-1-pri" {
  vpc_id = "${aws_vpc.test-1.id}"
  tags {
    Name = "test-1-pri"
  }
}

resource "aws_route_table_association" "test-1-pri" {
  subnet_id = "${aws_subnet.test-1a-pri.id}"
  route_table_id = "${aws_route_table.test-1-pri.id}"
}

resource "aws_subnet" "test-1a-pri" {
  vpc_id            = "${aws_vpc.test-1.id}"
  availability_zone = "eu-west-1a"
  cidr_block        = "10.0.10.0/24"

  tags {
    Name = "test-1a-pri"
  }
}

resource "aws_vpc" "rr-oai-test-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "rr-oai-test-vpc"
  }
}

resource "aws_internet_gateway" "rr-oai-test-igw" {
  vpc_id = aws_vpc.rr-oai-test-vpc.id
  tags = {
    Name = "rr-oai-test-igw"
  }
}

resource "aws_subnet" "rr-oai-test-subnet" {
  vpc_id     = aws_vpc.rr-oai-test-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "rr-oai-test-subnet"
  }
}

resource "aws_route" "internet_gateway" {
  route_table_id         = aws_vpc.rr-oai-test-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rr-oai-test-igw.id
}

// resource "aws_route_table" "rr-oai-test-route-table" {
//   vpc_id = aws_vpc.rr-oai-test-vpc.id
//   route {
//     cidr_block = "0.0.0.0/0"
//     gateway_id = aws_internet_gateway.rr-oai-test-igw.id
//   }
//   tags = {
//     Name = "rr-oai-test-route-table"
//   }
// }

resource "aws_security_group" "rr-oai-test-sg" {
  name_prefix = "rr-oai-test-sg"
  vpc_id = aws_vpc.rr-oai-test-vpc.id

  ingress {
    from_port = 0
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from any IP address"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_instance" "rr-oai-test-instance" {
  ami           = "ami-0d92f906962fb9003"
  instance_type = "${var.server_instance_type}"
  key_name      = "rr-key-2023-2"
  subnet_id     = aws_subnet.rr-oai-test-subnet.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.rr-oai-test-sg.id]

  provisioner "remote-exec" {
    inline = [
      "touch test"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/rr-key-2023-2.pem")
      host        = aws_instance.rr-oai-test-instance.public_ip
    }
  }

  tags = {
    Name = "${var.server_tag_name}"
  }
}

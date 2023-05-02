resource "aws_vpc" "oai-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.vpc_tag_name}-vpc"
  }
}

resource "aws_internet_gateway" "oai-igw" {
  vpc_id = aws_vpc.oai-vpc.id
  tags = {
    Name = "${var.vpc_tag_name}-igw"
  }
}

resource "aws_subnet" "oai-subnet-mngt" {
  vpc_id     = aws_vpc.oai-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "${var.vpc_tag_name}-sub-mngt"
  }
}
resource "aws_subnet" "oai-subnet-data" {
  vpc_id     = aws_vpc.oai-vpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "${var.vpc_tag_name}-sub-data"
  }
}

resource "aws_route" "internet_gateway" {
  route_table_id         = aws_vpc.oai-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.oai-igw.id
}


resource "aws_security_group" "oai-sg" {
  name_prefix = "${var.vpc_tag_name}-sg"
  vpc_id = aws_vpc.oai-vpc.id

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

resource "aws_instance" "oai-instance_1" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = [aws_subnet.oai-subnet-mngt.id,aws_subnet.oai-subnet-data.id]
  associate_public_ip_address = true
  security_groups = [aws_security_group.oai-sg.id]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp2"
  }
 
  provisioner "file" {
    source      = "${var.oai_deployment_file}"
    destination = "oai-deployment.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_file}")
      host        = aws_instance.oai-instance_1.public_ip
    }
  }
  tags = {
    Name = "${var.server1_tag_name}"
  }
}

resource "aws_instance" "oai-instance_2" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = [aws_subnet.oai-subnet-mngt.id,aws_subnet.oai-subnet-data.id]
  associate_public_ip_address = true
  security_groups = [aws_security_group.oai-sg.id]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp2"
  }
 
  provisioner "file" {
    source      = "${var.oai_deployment_file}"
    destination = "oai-deployment.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_file}")
      host        = aws_instance.oai-instance_2.public_ip
    }
  }
  tags = {
    Name = "${var.server2_tag_name}"
  }
}

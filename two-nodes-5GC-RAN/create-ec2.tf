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


resource "aws_security_group" "oai_managmement_sg" {
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
resource "aws_security_group" "oai_data_sg" {
  name_prefix = "${var.vpc_tag_name}-sg"
  vpc_id = aws_vpc.oai-vpc.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all"
  }
}

//
// Resources for networking (interfaces) referenced in the Instances
// eni1 (eth0) gets a public IP address ("Elastic IP")
//

resource "aws_network_interface" "instance_1_eni1" {
  subnet_id = aws_subnet.oai-subnet-mngt.id
  tags = {
    Name = "instance_1_eni1"
  }
  security_groups = [aws_security_group.oai_managmement_sg.id]
}
resource "aws_network_interface" "instance_2_eni1" {
  subnet_id = aws_subnet.oai-subnet-mngt.id
  tags = {
    Name = "instance_2_eni1"
  }
  security_groups = [aws_security_group.oai_managmement_sg.id]
}
resource "aws_eip" "eip_instance_1_eni1" {
  vpc = true
}
resource "aws_eip" "eip_instance_2_eni1" {
  vpc = true
}
resource "aws_eip_association" "eip_assoc1" {
  network_interface_id = aws_network_interface.instance_1_eni1.id
  allocation_id = aws_eip.eip_instance_1_eni1.id
}
resource "aws_eip_association" "eip_assoc2" {
  network_interface_id = aws_network_interface.instance_2_eni1.id
  allocation_id = aws_eip.eip_instance_2_eni1.id
}

resource "aws_network_interface" "instance_1_eni2" {
  subnet_id = aws_subnet.oai-subnet-data.id
  private_ips = ["10.0.2.10"]
  tags = {
    Name = "instance_1_eni2"
  }
  security_groups = [aws_security_group.oai_data_sg.id]
}
resource "aws_network_interface" "instance_2_eni2" {
  subnet_id = aws_subnet.oai-subnet-data.id
  private_ips = ["10.0.2.20"]
  tags = {
    Name = "instance_2_eni2"
  }
  security_groups = [aws_security_group.oai_data_sg.id]
}

resource "aws_instance" "oai-instance_1" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_instance_type}"
  key_name      = "${var.key_name}"
  source_dest_check = false

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.instance_1_eni1.id
  }

  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.instance_1_eni2.id
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp2"
  }
//  provisioner "file" {
//    for_each =  { for index, file in var.file_provisioners_5GC:
//    file.source => file
//    }
//    source     = each.value.source
//    destination = each.value.destination
//
//    connection {
//      user        = "ubuntu"
//      private_key = file(var.private_key_file)
//      host        = aws_instance.oai-instance_2.public_ip
//    }
//  }

//  provisioner "file" {
//    for_each = var.file_provisioners_5GC
//    source     = each.value["source"]
//    destination = each.value["destination"]
//
//    connection {
//      user        = "ubuntu"
//      private_key = file(var.private_key_file)
//      host        = aws_instance.oai-instance_2.public_ip
//    }
//  }
  tags = {
    Name = "${var.server1_tag_name}"
  }
}

resource "aws_instance" "oai-instance_2" {
  ami           = "${var.ami_id}"
  instance_type = "${var.server_instance_type}"
  key_name      = "${var.key_name}"
  source_dest_check = false

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.instance_2_eni1.id
  }

  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.instance_2_eni2.id
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp2"
  }
  provisioner "file" {
    source      = "file1"
    destination = "oai-deployment.sh"
    connection {
//      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_file}")
      host        = aws_instance.oai-instance_2.public_ip
    }
  }
  provisioner "file" {
    source      = "file2"
    destination = "file2"
    connection {
      user        = "ubuntu"
      private_key = file("${var.private_key_file}")
      host        = aws_instance.oai-instance_2.public_ip
    }
  }
  provisioner "file" {
    source      = "file3"
    destination = "file3"
    connection {
      user        = "ubuntu"
      private_key = file("${var.private_key_file}")
      host        = aws_instance.oai-instance_2.public_ip
    }
  }
  tags = {
    Name = "${var.server2_tag_name}"
  }
}

output "public_ip_instance1" {
  value = aws_eip.eip_instance_1_eni1.public_ip
}
output "public_ip_instance2" {
  value = aws_eip.eip_instance_2_eni1.public_ip
}
output "data_private_ip_instance1" {
  value = aws_network_interface.instance_1_eni2.private_ips
}
output "data_private_ip_instance2" {
  value = aws_network_interface.instance_2_eni2.private_ips
}
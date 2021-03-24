## AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

## Init Credentials Profile and Region
provider "aws" {
  profile = "default"
  region  = "us-east-1"
  shared_credentials_file = "/home/devops/credentials"
}


# VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.10.0.0/16"
  tags = {
    Name = "main"
  }
}

# availability zones

data "aws_availability_zones" "available" {
  state = "available"
}

#subnet public
resource "aws_subnet" "public" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.10.1.0/24"
 tags = {
   Name = "subnetpublic"
 }
}

#subnet private

resource "aws_subnet" "private" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.10.2.0/24"
 tags = {
   Name = "subnetprivate"
 }
}

#key pair

#resource "tls_private_key" "ssh" {
#  algorithm = "RSA"
#  rsa_bits = 4096
#}

#resource "aws_key_pair" "ssh" {
#  key_name = "FinalKey"
#  public_key = tls_private_key.ssh.public_key_openssh
#}

#output "ssh_private_key_pem" {
# value = tls_private_key.ssh.private_key_pem
#}

#output "ssh_public_key_pem" {
# value = tls_private_key.ssh.public_key_pem
#}



#Internet Gateway 

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

   tags = {
     Name = "igw"
   }

}

# Route Table Public and association

resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.main.id
  route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
  }
}


resource "aws_route_table_association" "publicroute" {
   subnet_id = aws_subnet.public.id
   route_table_id = aws_route_table.publicroute.id
}


#NAT GATEWAY
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public.id
  tags = {
    Name = "NatGateway"
  }

}
output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}


#Route table private and association
resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "privateroute" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.privateroute.id
}


#Security Group

resource "aws_security_group" "public" {
    
   name  = "public"
   description = "Security Group Public"
   vpc_id = aws_vpc.main.id
   
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 1723
    to_port = 1723
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port  = 0
    to_port = 0
    protocol = "47"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Public"
     Description = "Public Security Group"
   }
}
resource "aws_security_group" "frontend" {
   
   name  = "frontend"
   description = "Security Group Frontend"
   vpc_id = aws_vpc.main.id
   ingress {
       from_port = 22
       to_port = 22
       protocol = "tcp"
       cidr_blocks = ["10.10.2.220/32","10.10.1.36/32","10.10.2.64/32"]
   }
   ingress {
      from_port = 3002
      to_port = 3002
      protocol = "tcp"
      cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
      cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.10.2.68/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Frontend"
     Description = "Security Group Frontend"
   }
  
}
resource "aws_security_group" "backend" {

   name  = "backend"
   description = "Security Group Backend"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.10.2.220/32","10.10.1.36/32","10.10.2.64/32"]
   }
   ingress {
     from_port = 5000
     to_port = 5000
     protocol = "tcp"
     cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.10.2.68/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Backend"
      Description = "Security Group Backend"
    }

}
resource "aws_security_group" "database" {
   
   name  = "database"
   description = "Security Group database"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.10.2.60/32","10.10.1.36/32"]
   }
   ingress {
      from_port = 10000
      to_port = 35000
      protocol = "tcp"
      cidr_blocks = ["10.10.2.60/32"]
   }
   ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["10.10.2.68/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Database"
      Description = "Security Group Database"
   }
}

resource "aws_security_group" "jenkins" {
   
   name  = "jenkins"
   description = "Security Group Jenkins"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.10.1.36/32","10.10.2.220/32","10.10.2.60/32"]
   }
   ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
       from_port = 50000
       to_port = 50000
       protocol = "tcp"
       cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.10.2.68/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Jenkins"
     Description = "Security Group Jenkins"
   } 
 
}
resource "aws_security_group" "monitoring" {
   

   name  = "monitoring"
   description = "Security Group Monitoring"
   vpc_id = aws_vpc.main.id
   ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
      from_port = 9090
      to_port = 9090
      protocol = "tcp"
      cidr_blocks = ["10.10.1.36/32"]
   }
   ingress {
       from_port = 3000
       to_port = 3000
       protocol = "tcp"
       cidr_blocks = ["10.10.1.36/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Monitoring"
      Description = "Security Group Monitoring"
   }
}




# Instance Public
resource "aws_instance" "public" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.public.id
  private_ip        = "10.10.1.36"
  security_groups   = [aws_security_group.public.id]
  tags = {
    Name = "public"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 15
#    volume_type           = "gp2"
  }
}

resource "aws_eip" "lb" {
   instance = aws_instance.public.id
}

# Instance Frontend
resource "aws_instance" "frontend" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.small"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.private.id
  private_ip        = "10.10.2.220"
  security_groups   = [aws_security_group.frontend.id]
  tags = {
    Name = "frontend"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 12
#    volume_type           = "gp2"
  }
}

# Instance Backend
resource "aws_instance" "Backend" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.small"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.private.id
  private_ip        = "10.10.2.60"
  security_groups   = [aws_security_group.backend.id]
  tags = {
    Name = "backend"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 12
#    volume_type           = "gp2"
  }
}
# Instance Jenkins
resource "aws_instance" "jenkins" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.private.id
  private_ip        = "10.10.2.64"
  security_groups   = [aws_security_group.jenkins.id]
  tags = {
    Name = "jenkins"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 12
#    volume_type           = "gp2"
  }
}

# Instance Database
resource "aws_instance" "database" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.private.id
  private_ip        = "10.10.2.223"
  security_groups   = [aws_security_group.database.id]
  tags = {
    Name = "database"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 12
#    volume_type           = "gp2"
  }
}


# Instance Monitoring
resource "aws_instance" "monitoring" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.small"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "FinalKey"
  subnet_id         = aws_subnet.private.id
  private_ip        = "10.10.2.68"
  security_groups   = [aws_security_group.monitoring.id]
  tags = {
    Name = "monitoring"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 12
#    volume_type           = "gp2"
  }
}


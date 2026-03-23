# wordpress
resource "aws_security_group" "wordpress-sg" {
    name = "wordpress-sg"
    vpc_id = aws_vpc.wpdv2-vpc.id
    

    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.bastion-sg.id]
    }
    ingress {
        description = "http from alb"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
    }

    

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "priv-wordpress-sg"
    }    
}    

# Bastion
resource "aws_security_group" "bastion-sg" {
    name = "bastion-sg"
    vpc_id = aws_vpc.wpdv2-vpc.id

    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["100.12.185.44/32"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "bastion-sg"

    }
}

# alb
resource "aws_security_group" "alb-sg" {
    name = "alb-sg"
    vpc_id = aws_vpc.wpdv2-vpc.id

    ingress {
        description = "HTTP from anywhere"
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

    tags = {
        Name = "ALB security group"
    }
  
}



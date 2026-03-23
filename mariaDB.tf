# Creating DB subnet group
resource "aws_db_subnet_group" "mariaDB-subnet-group" {
    name = "mariadb-subnet-group"
    subnet_ids = [aws_subnet.private_sub[1].id, aws_subnet.private_sub[2].id]
}

# Creating security group for mariaDB
resource "aws_security_group" "rds-sg" {
    name = "rds-sg"
    vpc_id = aws_vpc.wpdv2-vpc.id

    ingress {
        description = "allowing traffic from wordpress ec2"
        from_port = "3306"
        to_port = "3306"
        protocol = "tcp"
        security_groups = [aws_security_group.wordpress-sg.id]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-mariadb-sg"
  }
}

# Creating database with mariaDB

resource "aws_db_instance" "mariaDB" {
    identifier = "wordpress-rds"
    engine = "mariadb"
    engine_version = "10.11.10"
    username = "admin"
    password = var.DB_passwd 
    instance_class = "db.t3.micro"
    allocated_storage = 20
    storage_type = "gp2"
    vpc_security_group_ids = [aws_security_group.rds-sg.id]
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.mariaDB-subnet-group.id
    skip_final_snapshot = true
  
}

resource "aws_instance" "bastion" {
    ami = var.ami
    instance_type = "t2.micro"
    key_name = "wpdv2-keys"
    subnet_id = aws_subnet.public[1].id
    vpc_security_group_ids = [aws_security_group.bastion-sg.id]
    associate_public_ip_address = true

    tags = {
        Name = "bastion-ec2"
    }


  
}

output "bastion_public_ip" {
    value = aws_instance.bastion.public_ip
  
}
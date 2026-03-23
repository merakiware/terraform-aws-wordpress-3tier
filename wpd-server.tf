# Creating ec2 wordpress server aws linux 2
resource "aws_instance" "wordpress-priv" {
    ami = var.ami
    instance_type = "t2.micro"
    key_name = "wpdv2-keys"
    subnet_id = aws_subnet.private_sub[1].id
    vpc_security_group_ids = [aws_security_group.wordpress-sg.id]
    associate_public_ip_address = false

    tags = {
      Name = "wordpress-priv"

    }

    user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
            sudo yum install -y httpd mariadb-server
            sudo systemctl start httpd
            sudo systemctl enable httpd
            sudo systemctl start mariadb
            sudo systemctl enable mariadb

            # Apache configure file
            sudo usermod -a -G apache ec2-user
            sudo chown -R ec2-user:apache /var/www
            sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
            find /var/www -type f -exec sudo chmod 0664 {} \;
            rm /var/www/html/phpinfo.php
            EOF


}
output "wordpress_private_ip" {
  value = aws_instance.wordpress-priv.private_ip
}

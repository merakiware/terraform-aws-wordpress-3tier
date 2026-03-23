resource "aws_ebs_volume" "priv-wpdv2" {
    size = 8
    type = "gp2"
    availability_zone = "us-east-1b"
  
}
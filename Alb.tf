# Creating application load balancer
resource "aws_lb" "alb" {
    name = "alb-main"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb-sg.id]
    subnets = aws_subnet.public[*].id
    enable_deletion_protection = false 

    tags = {
        Name = "${var.project}-alb"
    }
  
}

# Creating target group will forward traffic to the wordpress ec2
resource "aws_lb_target_group" "wordpress-tg" {
    name = "wordpress-target"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.wpdv2-vpc.id

    health_check {
      enabled = true
      interval = 30
      path = "/"
      port = "traffic-port"
      healthy_threshold = 3
      unhealthy_threshold = 3

    }
  
}

# attaching the wordpress ec2 to the target group
resource "aws_lb_target_group_attachment" "wpd_attach" {
    target_group_arn = aws_lb_target_group.wordpress-tg.arn
    target_id = aws_instance.wordpress-priv.id
    port = 80
}

# creating listerner
# This line creates the connection between the listener and the load balancer.
resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action { 
        type = "forward"
        target_group_arn = aws_lb_target_group.wordpress-tg.arn
      
    }
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}
  

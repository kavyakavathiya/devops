resource "aws_lb" "customer-management-alb" {
  name               = "customer-management-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.customer-management-public[*].id
  security_groups    = [aws_security_group.customer-management-alb-sg.id]

  tags = {
    Name = "customer-management-alb"
  }
}

resource "aws_lb_listener" "customer-management-alb-listener" {
  load_balancer_arn = aws_lb.customer-management-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.customer-management-target-group.arn
  }
}

resource "aws_lb_target_group" "customer-management-target-group" {
  name        = "customer-management-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.customer_management_vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/healthcheck"
    protocol            = "HTTP"
    port                = "5000"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


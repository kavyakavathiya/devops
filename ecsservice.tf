resource "aws_ecs_service" "customer-management-service" {
  depends_on = [
    aws_lb.customer-management-alb,
    aws_lb_listener.customer-management-alb-listener,
    aws_lb_target_group.customer-management-target-group,
  ]

  name            = "customer-management-service"
  cluster         = aws_ecs_cluster.customer_management_cluster.id
  task_definition = aws_ecs_task_definition.customer-management-task-def.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.customer-management-ecs-sg.id]
    subnets         = aws_subnet.customer-management-private-rs[*].id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.customer-management-target-group.arn
    container_name   = "backend"
    container_port   = 5000
  }
}


# resource "aws_ecs_service" "customer-management-service-ec2" {
#   name            = "customer-management-service-ec2"
#   cluster         = aws_ecs_cluster.customer_management_cluster.id
#   task_definition = aws_ecs_task_definition.customer-management-task-def-ec2.arn
#   desired_count   = 1

#   launch_type = "EC2"

#   network_configuration {
#     security_groups = [aws_security_group.customer-management-ecs-sg.id]
#     subnets         = aws_subnet.customer-management-private-rs[*].id
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.customer-management-target-group-ec2.arn
#     container_name   = "backend"
#     container_port   = 5000
#   }

#   depends_on = [aws_lb_target_group.customer-management-target-group-ec2]
# }

resource "aws_lb_target_group" "customer-management-target-group-ec2" {
  name        = "cm-target-group-ec2"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.customer_management_vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/healthcheck"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}


resource "aws_lb_listener_rule" "redirect_to_cdp_bi" {
  listener_arn = "${aws_lb_listener.customer-management-alb-listener.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.customer-management-target-group-ec2.arn}"
  }

  condition {
    path_pattern {
      values = ["/forward_to/*"]
    }
  }
}

# resource "aws_ecs_service" "ec2_service" {

#   name            = "ec2-service"

#   cluster         = aws_ecs_cluster.customer_management_cluster.arn

#   task_definition = aws_ecs_task_definition.customer-management-task-def-ec2.arn

#   desired_count   = 1

#   # launch_type     = "EC2"

#   capacity_provider_strategy {

#     capacity_provider = aws_ecs_capacity_provider.ec2.name

#     weight            = 1

#   }

#   network_configuration {

#     subnets          = aws_subnet.customer-management-private-rs[*].id

#     security_groups  = [aws_security_group.customer-management-ecs-sg.id]

#     # assign_public_ip = false

#   }

# }
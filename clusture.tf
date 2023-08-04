
# resource "aws_ecs_cluster" "customer_management_cluster" {
#   name = "CustomerManagementCluster"
# }


# resource "aws_launch_configuration" "launch_configuration" {

#   name_prefix = "customer-management-launch-config"

#   image_id = "ami-05548f9cecf47b442" # Replace with the desired AMI ID for your EC2 instances

#   instance_type = "t3.2xlarge" # Replace with your desired instance type

#   security_groups = [aws_security_group.customer-management-ecs-sg.id] # Replace with your security group ID(s)

#   # key_name        = aws_key_pair.my_ssh_key_pair.key_name

# }

# # Create auto scaling group for instances
# resource "aws_autoscaling_group" "asg" {

#   name = "customer-management-asg"

#   launch_configuration = aws_launch_configuration.launch_configuration.name

#   min_size = 1

#   max_size = 5

#   desired_capacity = 1 # Replace with your desired capacity

#   vpc_zone_identifier = aws_subnet.customer-management-private-rs[*].id # Replace with your subnet ID(s)

# }


# resource "aws_ecs_capacity_provider" "ec2" {

#   name = "capacity-provider-ec2-type"

#   auto_scaling_group_provider {

#     auto_scaling_group_arn = aws_autoscaling_group.asg.arn

#     managed_scaling {

#       status = "ENABLED"

#       minimum_scaling_step_size = 1

#       maximum_scaling_step_size = 100

#       target_capacity = 100

#     }

#   }

# }



# resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {

#   cluster_name = aws_ecs_cluster.customer_management_cluster.name

#   capacity_providers = ["FARGATE", aws_ecs_capacity_provider.ec2.name]

# }

 
resource "aws_ecs_cluster" "customer_management_cluster" {
  name = "CustomerManagementCluster"
}

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "customer-management-launch-config"
  image_id      = "ami-05548f9cecf47b442"  # Replace with the desired AMI ID for your EC2 instances
  instance_type = "t3.2xlarge"  # Replace with your desired instance type
  security_groups = [aws_security_group.customer-management-ecs-sg.id]  # Replace with your security group ID(s)

  # Add userdata to register instances with the ECS cluster
  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.customer_management_cluster.name} >> /etc/ecs/ecs.config
  EOF
}

# Create auto scaling group for instances
resource "aws_autoscaling_group" "asg" {
  name                 = "customer-management-asg"
  launch_configuration = aws_launch_configuration.launch_configuration.name
  min_size             = 1
  max_size             = 5
  desired_capacity     = 1  # Replace with your desired capacity
  vpc_zone_identifier  = [aws_subnet.customer-management-private-rs[0].id]  # Replace with your subnet ID(s)
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "capacity-provider-ec2-type"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.asg.arn

    managed_scaling {
      status                   = "ENABLED"
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
      target_capacity          = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  cluster_name      = aws_ecs_cluster.customer_management_cluster.name
  capacity_providers = ["FARGATE", aws_ecs_capacity_provider.ec2.name]
}

resource "aws_ecs_service" "customer-management-service-ec2" {
  name            = "customer-management-service-ec21"
  cluster         = aws_ecs_cluster.customer_management_cluster.id
  task_definition = aws_ecs_task_definition.customer-management-task-def-ec2.arn
  desired_count   = 1

  # launch_type = "EC2"
  capacity_provider_strategy {

    capacity_provider = aws_ecs_capacity_provider.ec2.name

    weight            = 1

  }


  network_configuration {
    security_groups = [aws_security_group.customer-management-ecs-sg.id]
    subnets         = aws_subnet.customer-management-private-rs[*].id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.customer-management-target-group-ec2.arn
    container_name   = "backend"
    container_port   = 5000
  }

  depends_on = [aws_lb_target_group.customer-management-target-group-ec2]
}

variable "my_proj_clus_name" {
  description = "Name of the ecs cluster"
  default = "mycluster"
}
variable "image_id" {
  description = "instance image id fro launch template"
  default = "ami-08a52ddb321b32a8c"
}
variable "instance_type" {
  description = "instance type launch template"
  default = "t3.small"
}
variable "security_groups" {
  description = "security group id for launch template"
  default = "sg-07792601ae4bb699c"
}
variable "create_before_destroy_lifecycle_policy_enabled" {
    description = "create_before_destroy life cycle policy true or false"
    type = bool
    default = true
  
}
variable "ecs_auto_scale" {
  description = "Configuration for ECS Auto Scaling Group"
  type = map(any)
 default = {
    max_size=4
    min_size=1
    vpc_zone_identifier="subnet-0e12e2bf768c7852e"
    desired_capacity= 1
    tag_key= "name"
    tag_value="test-ecs"
  }
}

variable "my-ecs-cap-provide-name" {
    default = "my-ecs-cap-provide"
    description = "my ecs capacity provide name"
  
}
//create cluster
resource "aws_ecs_cluster" "my-proj-clus" {
  name = var.my_proj_clus_name
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}


// create launch tamplate
resource "aws_launch_configuration" "my-launch-temp" {
  image_id = var.image_id
  instance_type = var.instance_type
  # iam_instance_profile = aws_iam_instance_profile.my-instance-profile.name
  security_groups = [ var.security_groups ]
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.my-proj-clus.name} >> /etc/ecs/ecs.config
              EOF
}

//create auto scalling group
resource "aws_autoscaling_group" "my-ecs-autoscale" {
  desired_capacity = var.ecs_auto_scale["desired_capacity"]
  min_size = var.ecs_auto_scale["min_size"]
  max_size = var.ecs_auto_scale["max_size"]
  vpc_zone_identifier = [var.ecs_auto_scale["vpc_zone_identifier"]]
  launch_configuration = aws_launch_configuration.my-launch-temp.id
  
  lifecycle {
    create_before_destroy = true
  }
  
  tag {
    key = var.ecs_auto_scale["tag_key"]
    value = var.ecs_auto_scale["tag_value"]
    propagate_at_launch = true
  }
}

//create capacity provider
resource "aws_ecs_capacity_provider" "my-capprovide" {
  name = var.my-ecs-cap-provide-name
  auto_scaling_group_provider {
    auto_scaling_group_arn =  aws_autoscaling_group.my-ecs-autoscale.arn
    # managed_termination_protection = "ENABLED"
    managed_scaling {
      status = "ENABLED"
      target_capacity = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "my-ecs-cp" {
  cluster_name = aws_ecs_cluster.my-proj-clus.name
  capacity_providers = ["FARGATE", aws_ecs_capacity_provider.my-capprovide.name]
}

//create tasdk def
resource "aws_ecs_task_definition" "my-proj-ec2-task" {
  family                   = "my-task-def"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  # cpu                      = 512
  # memory                   = 1024
  task_role_arn            = "arn:aws:iam::218459525783:role/blue-green-ecs-task-role"
  execution_role_arn       = "arn:aws:iam::218459525783:role/ecsTaskExecutionRole"

  container_definitions = file("/home/kavya/store-image-s3/terraform/container_def.json")

  
}   

//create ecs service

resource "aws_ecs_service" "ec2-service" {
  name            = "ec2-service"
  cluster         = aws_ecs_cluster.my-proj-clus.arn
  task_definition = aws_ecs_task_definition.my-proj-ec2-task.arn
  desired_count   = 1
  capacity_provider_strategy {
    base = 1
    weight = 1
    capacity_provider = "my-ecs-cap-provide"
  }
}

# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

resource "aws_ecr_repository" "image-store-backend-repo" {
  name = "image-store-backend-repo"
  # scan_on_push = true

  provisioner "local-exec" {
    command = <<EOT
      # Build Docker image
      cd /home/kavya/store-image-s3/server
      docker build -t image-store-backend:latest .
      
      # Get ECR login command
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.   image-store-backend-repo.repository_url}
      
      # Tag the image
      docker tag image-store-backend:latest ${aws_ecr_repository.   image-store-backend-repo.repository_url}:latest
      
      # Push the image to ECR
      docker push ${aws_ecr_repository.   image-store-backend-repo.repository_url}:latest
    EOT
  }

}
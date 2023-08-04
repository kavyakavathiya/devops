resource "aws_iam_role" "customer-management-ecs-task-execution-role" {
  name = "customer-management-ecs-task-execution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "customer-management-ecs-task-execution-role-policy" {
  role       = aws_iam_role.customer-management-ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "customer-management-ecs-task-execution-role-admin-access" {
  role       = aws_iam_role.customer-management-ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "customer-management-task-role" {
  name = "customer-management-task-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy" {
  role       = aws_iam_role.customer-management-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy2" {
  role       = aws_iam_role.customer-management-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy3" {
  role       = aws_iam_role.customer-management-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy4" {
#   role       = aws_iam_role.customer-management-task-role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonECSTaskExecutionRolePolicy"
# }

resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy5" {
  role       = aws_iam_role.customer-management-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}



# resource "aws_iam_role_policy_attachment" "customer-management-task-role-policy5" {
#   role       = aws_iam_role.customer-management-task-role.name
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
# }

resource "aws_cloudwatch_log_group" "customer-management-logs" {
  name = "customer-management-logs"
}

data "aws_ecr_repository" "customer-management-backend-repo" {
  name = aws_ecr_repository.customer-management-backend-repo.name
}


data "aws_db_instance" "customer-management-db-1" {
  db_instance_identifier = aws_db_instance.customer-management-db.identifier
}

data "aws_db_instance" "customer-management-db-endpoint" {
  db_instance_identifier = aws_db_instance.customer-management-db.identifier
}


resource "aws_ecs_task_definition" "customer-management-task-def" {
  family                   = "cm-test-td"
  execution_role_arn       = aws_iam_role.customer-management-ecs-task-execution-role.arn
  task_role_arn            = aws_iam_role.customer-management-task-role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096

  container_definitions = <<CONTAINER_DEFINITIONS
[
  {
    "name": "backend",
    "image": "${data.aws_ecr_repository.customer-management-backend-repo.repository_url}",
    "cpu": 0,
    "portMappings": [
      {
        "name": "backend-5000-tcp",
        "containerPort": 5000,
        "hostPort": 5000,
        "protocol": "tcp",
        "appProtocol": "http"
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "PORTFRONTEND",
        "value": "3000"
      },
      {
        "name": "MYHOST",
        "value": "${data.aws_db_instance.customer-management-db-endpoint.address}"
      },
      {
        "name": "PORTBACKEND",
        "value": "5000"
      },
      {
        "name": "DATABASE",
        "value": "myapp"
      }
    ],
    "secrets": [
      {
        "name": "MYUSERNAME",
        "valueFrom": "${aws_secretsmanager_secret_version.customer_management_db.arn}:username::"
      },
      {
        "name": "PASSWORD",
        "valueFrom": "${aws_secretsmanager_secret_version.customer_management_db.arn}:password::"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "true",
        "awslogs-group": "/ecs/cm-test-td",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
CONTAINER_DEFINITIONS

  depends_on = [
    aws_cloudwatch_log_group.customer-management-logs,
    aws_iam_role_policy_attachment.customer-management-task-role-policy,
    aws_iam_role_policy_attachment.customer-management-task-role-policy2,
    aws_iam_role_policy_attachment.customer-management-task-role-policy3,
    # aws_iam_role_policy_attachment.customer-management-task-role-policy4,
    aws_iam_role_policy_attachment.customer-management-task-role-policy5
  ]
}

resource "aws_ecs_task_definition" "customer-management-task-def-ec2" {
  family                   = "cm-test-td-ec2"
  execution_role_arn       = aws_iam_role.customer-management-ecs-task-execution-role.arn
  task_role_arn            = aws_iam_role.customer-management-task-role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 2048
  memory                   = 4096

  container_definitions = <<CONTAINER_DEFINITIONS
[
  {
    "name": "backend",
    "image": "${data.aws_ecr_repository.customer-management-backend-repo.repository_url}",
    "cpu": 0,
    "portMappings": [
      {
        "name": "backend-5000-tcp",
        "containerPort": 5000,
        "hostPort": 5000,  
        "protocol": "tcp",
        "appProtocol": "http"
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "PORTFRONTEND",
        "value": "3000"
      },
      {
        "name": "MYHOST",
        "value": "${data.aws_db_instance.customer-management-db-endpoint.address}"
      },
      {
        "name": "PORTBACKEND",
        "value": "5000"
      },
      {
        "name": "DATABASE",
        "value": "myapp"
      }
    ],
    "secrets": [
      {
        "name": "MYUSERNAME",
        "valueFrom": "${aws_secretsmanager_secret_version.customer_management_db.arn}:username::"
      },
      {
        "name": "PASSWORD",
        "valueFrom": "${aws_secretsmanager_secret_version.customer_management_db.arn}:password::"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "true",
        "awslogs-group": "/ecs/cm-test-td-ec2",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
CONTAINER_DEFINITIONS

  depends_on = [
    aws_cloudwatch_log_group.customer-management-logs,
    aws_iam_role_policy_attachment.customer-management-task-role-policy,
    aws_iam_role_policy_attachment.customer-management-task-role-policy2,
    aws_iam_role_policy_attachment.customer-management-task-role-policy3,
    aws_iam_role_policy_attachment.customer-management-task-role-policy5
  ]
}

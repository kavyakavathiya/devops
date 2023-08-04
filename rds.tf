resource "aws_db_subnet_group" "db_subnet_group" {
  depends_on  = [aws_route_table.customer-management-private-db-rt]
  name        = "customer-management-db-subnet-group"
  description = "My db subnet group"
  subnet_ids  = aws_subnet.customer-management-private-db[*].id
}

resource "random_password" "example" {
  length           = 16
  special          = true
  override_special = "_%]"
}

resource "aws_secretsmanager_secret" "customer-management-secret" {
  name = "CustomerManagementDatabaseCredential"
}

resource "aws_secretsmanager_secret_version" "customer_management_db" {
  secret_id = aws_secretsmanager_secret.customer-management-secret.id
  secret_string = jsonencode({
    username = "kavya",
    password = random_password.example.result
  })
}

resource "aws_db_instance" "customer-management-db" {
  depends_on = [aws_db_subnet_group.db_subnet_group]

  engine            = "mysql"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  identifier        = "customer-management-db"
  username          = "kavya"
  password          = random_password.example.result
  db_name           = "myapp"

  vpc_security_group_ids = [
    aws_security_group.customer-management-rds-sg.id
  ]

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = "customer-management-db"
  }
}

output "secret_manager_name" {
  value = aws_secretsmanager_secret.customer-management-secret.name
}

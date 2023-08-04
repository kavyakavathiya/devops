# resource "aws_ssm_parameter" "database" {
#   name  = "/customermanagement/DATABASE"
#   value = "myapp"
#   type  = "String"
# }

# resource "aws_ssm_parameter" "port_backend" {
#   name  = "/customermanagement/PORTBACKEND"
#   value = "5000"
#   type  = "String"
# }

# resource "aws_ssm_parameter" "port_frontend" {
#   name  = "/customermanagement/PORTFRONTEND"
#   value = "3000"
#   type  = "String"
# }

# data "aws_db_instance" "customer-management-db" {
#   db_instance_identifier = aws_db_instance.customer-management-db.identifier
# }

# resource "aws_ssm_parameter" "my_host" {
#   depends_on = [ aws_db_instance.customer-management-db ]
#   name  = "/customermanagement/MYHOST"
#   value = data.aws_db_instance.customer-management-db.endpoint
#   type  = "String"
# }

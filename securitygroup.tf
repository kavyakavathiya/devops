resource "aws_security_group" "customer-management-rds-sg" {
    depends_on = [ aws_security_group.customer-management-ecs-sg ]
    vpc_id = "${aws_vpc.customer_management_vpc.id}"
    name       = "customer-management-rds-sg"
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "customer-management-rds-sg"
    }
}

resource "aws_security_group" "customer-management-ecs-sg" {
    depends_on = [ aws_security_group.customer-management-alb-sg ]
    vpc_id = "${aws_vpc.customer_management_vpc.id}"
    name       = "customer-management-ecs-sg"
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "customer-management-ecs-sg"
    }
}

resource "aws_security_group" "customer-management-alb-sg" {
    depends_on = [ aws_vpc.customer_management_vpc ]
    vpc_id = "${aws_vpc.customer_management_vpc.id}"
    name       = "customer-management-alb-sg"
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "customer-management-alb-sg"
    }
}
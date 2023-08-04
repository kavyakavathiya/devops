provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "aws_ecr_repository" "customer-management-backend-repo" {
  name = "customer-management-backend-repo"
  # scan_on_push = true

  provisioner "local-exec" {
    command = <<EOT
      # Build Docker image
      cd /home/kavya/final-task/server
      docker build -t customer-management-backend:latest .
      
      # Get ECR login command
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.customer-management-backend-repo.repository_url}
      
      # Tag the image
      docker tag customer-management-backend:latest ${aws_ecr_repository.customer-management-backend-repo.repository_url}:latest
      
      # Push the image to ECR
      docker push ${aws_ecr_repository.customer-management-backend-repo.repository_url}:latest
    EOT
  }

}

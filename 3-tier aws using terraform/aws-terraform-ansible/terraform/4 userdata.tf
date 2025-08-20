
resource "aws_instance" "app" {
  ami                    = "ami-0a7d80731ae1b2435"    
  instance_type          = "t2.micro"
  subnet_id              = "subnet-051f56c48e3deb524 "
  vpc_security_group_ids =  ["sg-001421082900d2a9d"]  
  key_name               = "vijay"                  

  # Optional: user data for initial setup
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name = "my-app-instance"
  }
}


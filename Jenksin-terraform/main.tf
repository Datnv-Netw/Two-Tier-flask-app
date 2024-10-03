resource "aws_iam_role" "example_role" {
  name = "Jenkins-terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "example_profile" {
  name = "Jenkins-terraform"
  role = aws_iam_role.example_role.name
}


resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,8086,9090,5000"
  vpc_id      = "vpc-0a96ccab4bc26016a"
  # Define a single ingress rule to allow traffic on all specified ports
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000, 5000, 8086, 9090] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-sg"
  }
}
data "aws_vpc" "default" {
  filter {
    name   = "vpc-id"
    values = ["vpc-0a96ccab4bc26016a"]  # ID VPC của bạn
  }
}

# Lấy Subnet công (Public Subnet)
data "aws_subnet" "public" {
  filter {
    name   = "subnet-id"
    values = ["subnet-03211d3259f7b0dc5"]  # ID Subnet công của bạn
  }
}

# Lấy Subnet riêng (Private Subnet)
data "aws_subnet" "private" {
  filter {
    name   = "subnet-id"
    values = ["subnet-0b02f156a5cea73af"]  # ID Subnet riêng của bạn
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-005fc0f236362e99f"
  instance_type          = "t2.large"
  key_name               = "datcyber"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./script.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.example_profile.name  
  subnet_id              = data.aws_subnet.public.id
  
  tags = {
    Name = "Jenkins"
  }

  root_block_device {
    volume_size = 30
  }
}

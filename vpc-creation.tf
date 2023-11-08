### Change ssh key-pair accordingly


#VPC code

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#subnets

resource "aws_subnet" "pub-sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "pub-sub"
  }
}

resource "aws_subnet" "pri-sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pri-sub"
  }
}


#ssh keypair code
resource "aws_key_pair" "sampkey" {
  key_name   = "sample"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDnPNJWuR6U/Jw9UueeNpRWb6kPhup23zo1R1nWlMBL34lBcHCsgp5FYJuwIIrMXR6JKyWR8xa4sq8GECx/d4DwvhvuGz45Snz2OdU23YMfq1KDc5a0eGXjXUkZNoXzLh0/O64g4Il1XF51B00h+CDk31hwtBZtk0x5arqGsLA2L1OtdXPNVQqrXxTA8nnS4RDXVdBGmkSSJ9huvV3jXH8+OYtNoGPoQvCgJbCgOZqdwVolErv8FYOB8ErZkYnZxru/SNvu16uwvXJQcMa2U1PW20k6PcU/s/sp1HIdsatcK/+xtF8JOgfntmxATjAZYwu6fVaJdBPl3pnt5gs/qdjAZ1PsTxas+CqWrxhlLSP7l3cOigNcnGxTDqo8Y/QHhJ+4D5BckbeYn2l71GekMVojuDyMC4U5YleGwPM0ttAiWwLr4rogQ8tV6MPs3PgQ3a+MyzIsjoqHKCC/nFqz9TGb/kgzRtgQH9ay1qBriDIgLoEpaGnvUtkTx4o3ZX0TO8U= root@ip-172-31-38-138.ap-south-1.compute.internal"
}


#security group
resource "aws_security_group" "test_access" {
  name        = "test_access"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#internet gate way

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

#public route table

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  tags = {
    Name = "pub-rt"
  }
}

#route Table assosication code
resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.pub-sub.id
  route_table_id = aws_route_table.pub-rt.id
}

#ec2 code
resource "aws_instance" "pub-server" {
  ami             = "ami-0a6ed6689998f32a5"
  subnet_id       = "${aws_subnet.pub-sub.id}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_access.id}"]
  key_name        = "sample"
  associate_public_ip_address = "true"
  tags = {
    Name     = "pub-sub"
    Stage    = "testing"
    Location = "chennai"
  }

}

##create an EIP for EC2
resource "aws_eip" "pub-eip" {
  instance = "${aws_instance.pub-server.id}"
}

###this is database ec2 code
resource "aws_instance" "gautam-server" {
  ami             = "ami-0a6ed6689998f32a5"
  subnet_id       = "${aws_subnet.pri-sub.id}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_access.id}"]
  key_name        = "sample"
  tags = {
    Name     = "pri"
    Stage    = "stage-base"
    Location = "delhi"
  }
}


#eip for nat
resource "aws_eip" "nat-eip" {
}

### create Nat gateway
resource "aws_nat_gateway" "my-ngw" {
  allocation_id = "${aws_eip.nat-eip.id}"
  subnet_id     = "${aws_subnet.pub-sub.id}"
}

#create private route table
resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.my-ngw.id}"
  }


  tags = {
    Name = "pri-rt"
  }
}

##route Table assosication code
resource "aws_route_table_association" "private-asso" {
  subnet_id      = "${aws_subnet.pri-sub.id}"
  route_table_id = "${aws_route_table.pri-rt.id}"
}

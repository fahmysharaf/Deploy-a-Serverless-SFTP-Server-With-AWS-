data "aws_vpc" "sftp" {
  id = var.vpc-id
}

resource "aws_security_group" "endpoint" {
  description = "Security group for transfer.server endpoint"
  name        = "transfer-server-endpoint-sg"
  tags = {
    Name  = "transfer-server-endpoint-sg"
  }
  vpc_id = var.vpc-id
}

resource "aws_security_group_rule" "endpoints-https" {
  cidr_blocks = [
    data.aws_vpc.sftp.cidr_block
  ]
  description       = "SSH from within this VPC"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.endpoint.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_vpc_endpoint" "transfer-server" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoint.id]
  service_name        = "com.amazonaws.${var.region}.transfer.server"
  subnet_ids          = var.subnet-ids
  tags = {
    Name  = "transfer-server-endpoint"
  }
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc-id
}


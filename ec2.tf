resource "aws_eip" "a" {
  tags = {
    Name = "${var.name}-nlb-eip-a"
  }
  vpc = true
}

resource "aws_eip" "b" {
  tags = {
    Name = "${var.name}-nlb-eip-b"
  }
  vpc = true
}

resource "aws_alb" "sftp" {
  internal           = "false"
  load_balancer_type = "network"
  name               = "${var.name}-nlb"
  subnet_mapping {
    subnet_id = element(
      flatten([var.nlb-subnet-ids]),
      0,
    )
    allocation_id = aws_eip.a.id
  }
  subnet_mapping {
    subnet_id = element(
      flatten([var.nlb-subnet-ids]),
      1,
    )
    allocation_id = aws_eip.b.id
  }
  tags = {
    Name = "${var.name}-nlb"
  }
}

resource "aws_alb_listener" "sftp" {
  default_action {
    target_group_arn = aws_alb_target_group.sftp.arn
    type             = "forward"
  }
  load_balancer_arn = aws_alb.sftp.arn
  port              = "22"
  protocol          = "TCP"
}

resource "aws_alb_target_group" "sftp" {
  name        = "${var.name}-tg"
  port        = "22"
  protocol    = "TCP"
  tags = {
    Name = "${var.name}-tg"
  }
  target_type = "ip"
  vpc_id      = var.vpc-id
}

data "aws_network_interface" "eni_0" {
  id = element(flatten([aws_vpc_endpoint.transfer-server.network_interface_ids]),0,)
}

data "aws_network_interface" "eni_1" {
  id = element(flatten([aws_vpc_endpoint.transfer-server.network_interface_ids]),1,)
}

resource "aws_lb_target_group_attachment" "sftp" {
  target_group_arn = aws_alb_target_group.sftp.arn
  target_id        = data.aws_network_interface.eni_0.private_ips[0]
}

resource "aws_lb_target_group_attachment" "sftp-2" {
  target_group_arn = aws_alb_target_group.sftp.arn
  target_id        = data.aws_network_interface.eni_1.private_ips[0]
}

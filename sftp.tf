data "aws_iam_policy_document" "transfer" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "transfer.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "cloudwatch" {
  assume_role_policy = data.aws_iam_policy_document.transfer.json
  name               = "${var.name}-cloudwatch-role"
  path               = "/"
  tags = {
    Name    = "${var.name}-cloudwatch-role"
  }
}

data "template_file" "cloudwatch" {
  template = file(
    "${path.module}/templates/cloudwatch-policy.json.tpl",
  )
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "${var.name}"
  policy = data.template_file.cloudwatch.rendered
  role   = aws_iam_role.cloudwatch.id
}


resource "aws_iam_role" "idp" {
  assume_role_policy = data.aws_iam_policy_document.transfer.json
  name               = "${var.name}-idp-role"
  path               = "/"
  tags = {
    Name    = "${var.name}-idp-role"
  }
}

data "template_file" "idp" {
  template = file(
    "${path.module}/templates/idp-policy.json.tpl"
  )
  vars = {
    aws_account_id = data.aws_caller_identity.current.account_id
    api            = aws_api_gateway_rest_api.idp.id
    region         = var.region
  }
}

resource "aws_iam_role_policy" "idp" {
  name   = "${var.name}"
  policy = data.template_file.idp.rendered
  role   = aws_iam_role.idp.id
}


resource "aws_transfer_server" "transfer" {
  endpoint_details {
    vpc_endpoint_id = aws_vpc_endpoint.transfer-server.id
  }
  endpoint_type          = "VPC_ENDPOINT"
  identity_provider_type = "API_GATEWAY"
  invocation_role        = aws_iam_role.idp.arn
  logging_role           = aws_iam_role.cloudwatch.arn
  tags = {
    Name = "${var.name}-transfer-server"
  }
  url = "https://${aws_api_gateway_rest_api.idp.id}.execute-api.${var.region}.amazonaws.com/prod"
}

resource "aws_iam_role" "users" {
  assume_role_policy = data.aws_iam_policy_document.transfer.json
  name               = "${var.name}-users-role"
  path               = "/"
  tags = {
    Name    = "${var.name}-users-role"
  }
}

data "template_file" "users" {
  template = file(
    "${path.module}/templates/users-policy.json.tpl"
  )
  vars = {
    aws_account_id = data.aws_caller_identity.current.account_id
    name           = var.name
    region         = var.region
  }
}

resource "aws_iam_role_policy" "users" {
  name   = "${var.name}"
  policy = data.template_file.users.rendered
  role   = aws_iam_role.users.id
}

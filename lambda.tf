data "aws_iam_policy" "lambda-basic" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.lambda.json
  name               = "${var.name}-lambda-role"
  path               = "/"
  tags = {
    Name    = "${var.name}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda-basic" {
  policy_arn = data.aws_iam_policy.lambda-basic.arn
  role       = aws_iam_role.lambda.name
}

data "template_file" "lambda" {
  template = file(
    "${path.module}/templates/lambda-policy.json.tpl",
  )
  vars = {
    aws_account_id = data.aws_caller_identity.current.account_id
    name           = var.name
    region         = var.region
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}"
  policy = data.template_file.lambda.rendered
  role   = aws_iam_role.lambda.id
}

data "archive_file" "get-user-config" {
  output_path = ".lambda/get-user-config.zip"
  source_dir  = "lambda-src/get-user-config"
  type        = "zip"
}

resource "aws_lambda_function" "get-user-config" {
  environment {
    variables = {
      AWS_ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
      SERVER_ID      = "${aws_transfer_server.transfer.id}"
      STACK_NAME     = "${var.name}"
    }
  }
  filename         = ".lambda/get-user-config.zip"
  function_name    = "${var.name}-get-user-config"
  handler          = "lambda_function.lambda_handler"
  publish          = "true"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.7"
  source_code_hash = data.archive_file.get-user-config.output_base64sha256
  tags = {
    Name    = "${var.name}-get-user-config"
  }
}


resource "aws_lambda_permission" "get-user-config" {
  action        = "lambda:InvokeFunction"
  depends_on    = [aws_api_gateway_deployment.idp]
  function_name = "${var.name}-get-user-config"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.idp.execution_arn}/*/*/*"
}

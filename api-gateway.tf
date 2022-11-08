resource "aws_api_gateway_rest_api" "idp" {
  name  = "${var.name}-idp"
}

resource "aws_api_gateway_resource" "servers" {
  rest_api_id = aws_api_gateway_rest_api.idp.id
  parent_id   = aws_api_gateway_rest_api.idp.root_resource_id
  path_part   = "servers"
}

resource "aws_api_gateway_resource" "serverid" {
  rest_api_id = aws_api_gateway_rest_api.idp.id
  parent_id   = aws_api_gateway_resource.servers.id
  path_part   = "{serverId}"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.idp.id
  parent_id   = aws_api_gateway_resource.serverid.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "username" {
  rest_api_id = aws_api_gateway_rest_api.idp.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{username}"
}

resource "aws_api_gateway_resource" "userconfig" {
  rest_api_id = aws_api_gateway_rest_api.idp.id
  parent_id   = aws_api_gateway_resource.username.id
  path_part   = "config"
}

resource "aws_api_gateway_model" "idp" {
  depends_on  = [aws_api_gateway_resource.userconfig]
  rest_api_id  = aws_api_gateway_rest_api.idp.id
  name         = "UserConfigResponseModel"
  description  = "API response for GetUserConfig"
  content_type = "application/json"
  schema = <<EOF
{
  "$schema":"http://json-schema.org/draft-04/schema#",
  "title":"UserUserConfig",
  "type":"object",
  "properties":{
    "Role":{
      "type":"string"
    },
    "Policy":{
      "type":"string"
    },
    "HomeDirectory":{
      "type":"string"
    },
    "PublicKeys":{
      "type":"array",
      "items":{
        "type":"string"
      }
    }
  }
}
EOF
}

resource "aws_api_gateway_integration" "idp" {
  depends_on  = [aws_api_gateway_model.idp]
  rest_api_id = aws_api_gateway_rest_api.idp.id
  resource_id = aws_api_gateway_resource.userconfig.id
  http_method = aws_api_gateway_method.idp.http_method
  type        = "AWS"
  request_templates = {
    "application/json" = <<EOF
{
  "username": "$input.params('username')",
  "password": "$util.escapeJavaScript($input.params('Password')).replaceAll("\\'","'")",
  "serverId": "$input.params('serverId')"
}
EOF
  }
  integration_http_method = "POST"
  uri = aws_lambda_function.get-user-config.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
  depends_on  = [aws_api_gateway_model.idp]
  rest_api_id = aws_api_gateway_rest_api.idp.id
  resource_id = aws_api_gateway_resource.userconfig.id
  http_method = aws_api_gateway_method.idp.http_method
  status_code = "200"
  response_models = {
    "application/json" = "UserConfigResponseModel"
  }
}

resource "aws_api_gateway_integration_response" "idp" {
  depends_on  = [aws_api_gateway_integration.idp]
  rest_api_id = aws_api_gateway_rest_api.idp.id
  resource_id = aws_api_gateway_resource.userconfig.id
  http_method = aws_api_gateway_method.idp.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}

resource "aws_api_gateway_method" "idp" {
  depends_on    = [aws_api_gateway_model.idp]
  rest_api_id   = aws_api_gateway_rest_api.idp.id
  resource_id   = aws_api_gateway_resource.userconfig.id
  http_method   = "GET"
  authorization = "AWS_IAM"
  request_parameters = {
    "method.request.header.Password" = false
  }
}

resource "aws_api_gateway_deployment" "idp" {
  depends_on  = [aws_api_gateway_integration.idp]
  rest_api_id = aws_api_gateway_rest_api.idp.id
  stage_name  = "prod"
}

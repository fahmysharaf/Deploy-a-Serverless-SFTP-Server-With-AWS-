{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "apigateway:GET"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": "arn:aws:execute-api:${region}:${aws_account_id}:${api}/prod/GET/*",
      "Effect": "Allow"
    }
  ]
}

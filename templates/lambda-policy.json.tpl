{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:${region}:${aws_account_id}:secret:${name}/*",
      "Effect": "Allow"
    }
  ]
}

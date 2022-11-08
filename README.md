# sftp
Deploy a serverless SFTP server with AWS.

# Terraform Deploy Instructions
To deploy run:
```
terraform init
terraform apply
```

# Post Deploy Update SSH Host Key
After the stack deploys you can update the SSH host key with the following:
```
aws transfer update-server --server-id `terraform state show aws_transfer_server.transfer |grep "= \"s-" |grep -v "amazonaws.com" |cut -d '=' -f2 |xargs` --host-key file://~/rsa-host-key
```


# Deploy-a-Serverless-SFTP-Server-With-AWS-

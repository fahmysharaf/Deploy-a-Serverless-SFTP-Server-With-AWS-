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
Requirements

First let’s define our requirements. The solution we build must meet the following demands:

    High availability – minimum 2 availability zones;
    Allow password and public key authentication;
    Should be “chroot” enabled so users can only view their own files;
    Allow for IP whitelisting to control access;
    User’s data should be encrypted;
    Use an existing DNS record to point to the server’s endpoint;
    Keep an existing SSH host key;

Design

The requirements for this SFTP server can be satisfied with the following design.

In this design we will use the AWS Transfer for SFTP service to provision an endpoint for our SFTP server. This service does not currently support password based authentication so we need to configure our own identity provider. For our IDP we will use API Gateway calling a Lambda function with the user credentials stored in AWS Secrets Manager. For the file storage we will use S3 with encryption enabled.

Our requirements demand that we implement IP whitelisting to control access to the SFTP server. The out of the box implementation of the AWS Transfer for SFTP service deploys a public endpoint. So we will instead deploy this using a VPC endpoint. A network load balancer will then be deployed across two availability zones with a target group configured to point to the IPs of our “transfer.server” VPC endpoint. We then create a Route 53 alias record pointing to the DNS record for the network load balancer.
Terraform


Now we can deploy the stack with Terraform:

$ terraform init
...
Terraform has been successfully initialized!
$ terraform apply
...

Plan: 36 to add, 0 to change, 0 to destroy.
 
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_alb_target_group.sftp: Creating...
aws_eip.a: Creating...
aws_eip.b: Creating...
...
Creation complete after 1s


Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

Adding Users

With the stack deployed we can now add our users. Let’s add two users. One using public key authentication and the other using password authentication.

Open the AWS Secrets Manager service and click on “Store a new secret”. For secret type, select “Other type of secrets”. Enter “Password” as the key and we can enter the password we would like to set for this user.

On the next page we need to give the secret a name. The format of the name is ${stackName}/${userName} where the stack name is the value of the “name” variable from the Terraform’s vars.tf file. In this example I am creating a user called “foo” with a stack name of “serverlessftp” so my secret name is “serverlessftp/foo”.

To create a user that uses public key authentication the process is the same except the name of the secret key is “PublicKey” with the value of course being the public key of the SSH key pair.
Bucket Layout

The layout of the S3 bucket containing the files for our server is a list of all user folders. So when creating a new user you should also create a folder in the bucket.
IP Whitelisting

Should you wish to limit the ingress to your SFTP server you can do so by adjusting the network access control list NACL rules on your subnets.
SSH Host Key

To preserve the SSH host key we update the AWS Transfer for SFTP server post deployment and provide our own SSH host key. This can only be done from the CLI but is as simple as:

$ aws transfer update-server --server-id s-abcd1234abcd12345 --host-key file:///path/to/your/host-key

Route 53

To create a Route 53 record pointing to your SFTP endpoint, first obtain the DNS name of the network load balancer.

$ terraform state show aws_alb.sftp |grep "dns_name" |cut -d '=' -f2 |xargs
serverlessftp-nlb-64364eab63a9352.elb.us-east-1.amazonaws.com

You can then create an alias record pointing to this.
Usage

Now we are ready to try this out. Let’s use WinSCP to configure access to our server.

Now let’s test it…

Success! Notice also how the user has no view beyond their folder in the S3 bucket so our “chroot” is working. So what about public key authentication…

$ sftp -i ~/bar bar@ftp.example.com
Connected to ftp.example.com.
sftp> ls
bar.txt
sftp>

That’s working too!
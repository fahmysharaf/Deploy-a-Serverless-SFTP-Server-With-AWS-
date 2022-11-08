import os
import json
import boto3
import base64
from botocore.exceptions import ClientError

def lambda_handler(event, context):
  global AWS_ACCOUNT_ID, AWS_REGION, BUCKET_NAME, SERVER_ID, STACK_NAME
  AWS_ACCOUNT_ID = os.environ['AWS_ACCOUNT_ID']
  AWS_REGION = os.environ['AWS_REGION']
  SERVER_ID = os.environ['SERVER_ID']
  STACK_NAME = os.environ['STACK_NAME']
  BUCKET_NAME = STACK_NAME + "-" + AWS_REGION + "-" + AWS_ACCOUNT_ID

  resp_data = {}

  if 'username' not in event or 'serverId' not in event:
    print("Incoming username or serverId missing!")
    return {}

  input_username = event['username']
  print("Username: {}, ServerId: {}".format(input_username, event['serverId']));
  if event['serverId'] != SERVER_ID:
    print("Invalid serverId!")
    return {}

  if 'password' in event:
    input_password = event['password']
  else:
    print("No password, checking for SSH public key")
    input_password = ''

  # Lookup user's secret which can contain the password or SSH public keys
  resp = get_secret(STACK_NAME + "/" + input_username)

  if resp != None:
    resp_dict = json.loads(resp)
  else:
    print("Secrets Manager exception thrown")
    return {}

  if input_password != '':
    if 'Password' in resp_dict:
      resp_password = resp_dict['Password']
    else:
      print("Unable to authenticate user - No field match in Secret for password")
      return {}

    if resp_password != input_password:
      print("Unable to authenticate user - Incoming password does not match stored")
      return {}
  else:
    # SSH Public Key Auth Flow - The incoming password was empty so we are trying ssh auth and need to return the public key data if we have it
    if 'PublicKey' in resp_dict:
      resp_data['PublicKeys'] = [resp_dict['PublicKey']]
    else:
      print("Unable to authenticate user - No public keys found")
      return {}

  # If we've got this far then we've either authenticated the user by password or we're using SSH public key auth and
  # we've begun constructing the data response. Check for each key value pair.
  # These are required so set to empty string if missing
  resp_data['Role'] = "arn:aws:iam::" + AWS_ACCOUNT_ID + ":role/" + STACK_NAME + "-users-role"
  resp_data['Policy'] = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"s3:ListBucket\",\"s3:GetBucketLocation\"],\"Effect\":\"Allow\",\"Resource\":[\"arn:aws:s3:::" + BUCKET_NAME + "\"]},{\"Effect\":\"Allow\",\"Action\":[\"s3:PutObject\",\"s3:GetObject\",\"s3:DeleteObjectVersion\",\"s3:DeleteObject\",\"s3:GetObjectVersion\"],\"Resource\":\"arn:aws:s3:::" + BUCKET_NAME + "/" + input_username + "/*\"}]}"
  resp_data['HomeDirectoryType'] = "LOGICAL"
  resp_data['HomeDirectoryDetails'] = "[{'Entry': '/', 'Target': '/" + BUCKET_NAME + "/" + input_username + "'}]"

  print("Completed Response Data: "+json.dumps(resp_data))
  return resp_data

def get_secret(id):
  print("Secrets Manager Region: " + AWS_REGION)

  client = boto3.session.Session().client(service_name='secretsmanager', region_name=AWS_REGION)

  try:
    resp = client.get_secret_value(SecretId=id)
    # Decrypts secret using the associated KMS CMK.
    # Depending on whether the secret is a string or binary, one of these fields will be populated.
    if 'SecretString' in resp:
      print("Found Secret String")
      return resp['SecretString']
    else:
      print("Found Binary Secret")
      return base64.b64decode(resp['SecretBinary'])
  except ClientError as err:
    print('Error Talking to SecretsManager: ' + err.response['Error']['Code'] + ', Message: ' + str(err))
    return None

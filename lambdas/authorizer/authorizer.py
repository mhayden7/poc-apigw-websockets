def lambda_handler(event, context):    
    token = event['queryStringParameters']['token']
    
    deny_policy = {
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': 'Deny',
                'Resource': 'arn:aws:execute-api:*:*:*/*/*/*'}]
        }
    }
    
    allow_policy = {
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': 'Allow',
                'Resource': 'arn:aws:execute-api:*:*:*/*'}]
            }
        }
    
    policy = deny_policy
    if token == 'letmein':
        policy = allow_policy
    
    return policy

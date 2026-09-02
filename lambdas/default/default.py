import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

default_message = '''
Use the subscribe route to subscribe to events. Example: {"action": "subscribe", "event_type": "<event name>", "session_id": "<your session id>"}
Use the publish route to send messages. Example: {"action": "publish", "event_type": "<event name>", "payload": "<your data here!>"}
'''

def lambda_handler(event, context):
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    endpoint_url = f"https://{domain_name}/{stage}"
    apigw_client = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint_url)
    connection_id = event["requestContext"]["connectionId"]
    
    connection_info = {}
    
    try:
        # Get connection info
        connection_info = client.get_connection(ConnectionId=connection_id)
    except Exception as e:
        logging.exception(f"Error: {e}")
    
    # Add connection ID to the info
    connection_info['connectionID'] = connection_id
    
    # Send message back to client
    try:
        apigw_client.post_to_connection(
            ConnectionId=connection_id,
            Data=default_message
        )
    except Exception as e:
        print(f"Error sending message: {e}")
    
    return {
        'statusCode': 200,
    }
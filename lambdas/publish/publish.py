import boto3
from boto3.dynamodb.conditions import Key, Attr
# from datetime import datetime
import json
import logging
import os
# from zoneinfo import ZoneInfo

# timezone = "America/New_York"

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    try:
        apigw_client = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['management_url'])
        connection_id = event["requestContext"]["connectionId"]
        data = json.loads(event['body'])
        last_key = None        

        while True:
            subscriptions, last_key = get_subscriptions(data.get('event_type'), last_key)    
            logger.info(subscriptions)
            for sub in subscriptions:
                session = get_session(sub.get('session_id'))
                apigw_client.post_to_connection(
                        ConnectionId=session.get('connection_id'),
                        Data=json.dumps({'event_type': data.get('event_type'), 'payload': data.get('payload')})
                    )
            if not last_key:
                break
    except Exception as err:
        logger.exception(err)
        return {"statusCode": 500}

    return {"statusCode": 200}


def get_subscriptions(event_type, last_key):
    query_parameters = {
        'IndexName': 'SubscriptionByEventType',
        'KeyConditionExpression': Key('GSI2PK').eq(f'EVENT_TYPE#{event_type}')
    }

    if last_key:
        query_parameters['ExclusiveStartKey'] = last_key

    response = table.query(**query_parameters)

    return response['Items'], response.get('LastEvaluatedKey')


def get_session(session_id):
    response = table.get_item(
        Key={'PK': 'SESSION#', 'SK': f'ID#{session_id}'}
    )

    return response.get('Item')
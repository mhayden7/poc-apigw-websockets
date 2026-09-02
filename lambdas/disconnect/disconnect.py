import boto3
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
import json
import logging
import os
from zoneinfo import ZoneInfo

timezone = "America/New_York"

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def lambda_handler(event, context):  
    batch_item_failures = []
    sqs_batch_response = {}

    for record in event['Records']:
        try:
            connection_id = record['body']
            sessions = get_session(connection_id)

            for session in sessions:
                if (datetime.now(ZoneInfo(timezone)) - datetime.fromisoformat(session.get('activity_time'))).total_seconds() > 300:
                    last_key = None

                    # delete subscriptions
                    while True:
                        subscriptions, last_key = get_subscriptions(session.get('session_id'), last_key)
                        for subscription in subscriptions:
                            table.delete_item(Key={'PK': subscription['PK'], 'SK': subscription['SK']})
                        if not last_key:
                            break
                            
                    # delete session
                    table.delete_item(Key={'PK': 'SESSION#', 'SK': f'ID#{session.get('session_id')}'})

        except Exception as err:
            batch_item_failures.append({"itemIdentifier": record['messageId']})
            logger.exception(err)
    
    sqs_batch_response["batchItemFailures"] = batch_item_failures
    return sqs_batch_response


def get_session(connection_id):
    response = table.query(
        IndexName = "SessionByConnectionId",
        KeyConditionExpression=Key("GSI1PK").eq(connection_id)
    )
    return response['Items']


def get_subscriptions(session_id, last_key):
    query_parameters = {'KeyConditionExpression': Key('PK').eq(f'SESSION#{session_id}')}
    if last_key:
        query_parameters['ExclusiveStartKey'] = last_key
    
    response = table.query(**query_parameters)
    return response['Items'], response.get('LastEvaluatedKey')
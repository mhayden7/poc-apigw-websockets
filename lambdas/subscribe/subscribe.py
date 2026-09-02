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
    try:
        data = json.loads(event['body'])
        session_id = data.get('session_id')
        update_session_activity_time(session_id)

        event_type = data.get('event_type')
        create_subscription(session_id, event_type)
    except Exception as err:
        logger.exception(err)
        return {"statusCode": 500}
        # TODO: send message about failure?

    return {"statusCode": 200}

def update_session_activity_time(session_id):
    table.update_item(
        Key = {'PK': 'SESSION#', 'SK': f'ID#{session_id}'},
        UpdateExpression='SET #attr = :val',
        ExpressionAttributeNames={'#attr': 'activity_time'},
        ExpressionAttributeValues={':val': datetime.now(ZoneInfo(timezone)).isoformat()}
    )


def create_subscription(session_id, event_type):
    item = {
        'PK': f'SESSION#{session_id}',
        'SK': f'EVENT_TYPE#{event_type}',
        'GSI2PK': f'EVENT_TYPE#{event_type}',
        'session_id': session_id
    }
    table.put_item(Item=item)

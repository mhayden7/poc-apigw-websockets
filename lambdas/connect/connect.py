import boto3
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
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
        connection_id = event["requestContext"]["connectionId"]
        params = event.get('queryStringParameters') or {}
        session_id = params.get('session_id')

        session = get_session(session_id)

        if session:            
            session['connection_id'] = connection_id
            update_session(session)
        else:
            session = create_session(connection_id, session_id)
    except Exception as err:
        logger.exception(err)
        return {"statusCode": 500}

    return {"statusCode": 200}


def get_session(session_id):
    response = table.get_item(
        Key={'PK': 'SESSION#', 'SK': f'ID#{session_id}'}
    )

    return response.get('Item')


def create_session(connection_id, session_id):
    item = {
        'PK': 'SESSION#',
        'SK': f'ID#{session_id}',
        'create_time': datetime.now(ZoneInfo(timezone)).isoformat(),
        'activity_time': datetime.now(ZoneInfo(timezone)).isoformat(),
        'connection_id': connection_id,
        'session_id': session_id,
        'GSI1PK': connection_id
    }
    table.put_item(Item=item)
    return item


def update_session(session):
    table.update_item(
        Key = {'PK': 'SESSION#', 'SK': f'ID#{session.get('session_id')}'},
        UpdateExpression='SET #attr = :val, #attr2 = :val2, #attr3 = :val3',
        ExpressionAttributeNames={'#attr': 'activity_time', '#attr2': 'connection_id', '#attr3': 'GSI1PK'},
        ExpressionAttributeValues={':val': datetime.now(ZoneInfo(timezone)).isoformat(), ':val2': session.get('connection_id'), ':val3': session.get('connection_id')}
    )
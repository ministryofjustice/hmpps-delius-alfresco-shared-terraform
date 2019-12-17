from app.logging_handler import get_logger
from app.config import Config
from app.slack_handler import Slack_Handler

import json

# setup logging
logger = get_logger()

# message handler


def message_handler(message_obj):
    # setup slack handler
    log_obj = {
        'status': 'not sent',
        'send_status': Config.slack_messaging_status,
        'data': message_obj
    }
    if Config.slack_messaging_status == "enabled":
        slack_handler = Slack_Handler()
        response = slack_handler.send_message(message_obj)
        if response['ok'] == True:
            log_obj['status'] = 'sent'
            log_obj['timestamp'] = response['ts']
            log_obj['channel'] = response['channel']
            log_obj['bot_id'] = response['bot_id']

    logger.debug({'message': log_obj})

    return log_obj

# Main function


def lambda_handler(event, context):
    environment_name = Config.environment_name
    log_obj = {
        'function_name': context.function_name,
        'status': 'starting',
        'environment': environment_name
    }
    logger.info({'message': log_obj})

    # alarm data
    alarm_data = json.loads(event['Records'][0]['Sns']['Message'])
    logger.debug({'message': alarm_data})

    # alarm type needs to lower case
    alarm_type = alarm_data['NewStateValue']

    # alarm name
    alarm_name = "{} - {}".format(
        environment_name,
        alarm_data['AlarmName']
    )

    # slack message fields
    message_obj = {
        'text': alarm_data['Trigger'],
        'title': alarm_name,
        'emoji_type': alarm_type.lower()
    }
    logger.info({'message': message_obj})

    # call message handler
    result = message_handler(message_obj)
    logger.info({'message': result})

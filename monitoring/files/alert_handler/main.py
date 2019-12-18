from app.logging_handler import get_logger
from app.utils import alarm_formatter
from app.config import Config

import json

# setup logging
logger = get_logger()

# message handler


def message_handler(message_obj):
    # setup slack handler
    from app.slack_handler import Slack_Handler
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

    logger.debug({
        'message': {
            'variable': 'message_obj',
            'value': message_obj
        }
    })

    return log_obj

# Main function


def lambda_handler(event, context):
    environment_name = Config.environment_name
    log_obj = {
        'function_name': context.function_name,
        'status': 'starting',
        'environment': environment_name
    }
    logger.info({
        'message': {
            'variable': 'log_obj',
            'value': log_obj
        }
    })

    # alarm data
    alarm_data = json.loads(event['Records'][0]['Sns']['Message'])

    # alarm name
    alarm_fields = alarm_formatter(alarm_data['AlarmName'])

    # alarm fields
    application = alarm_fields['application']
    service = alarm_fields['service']
    metric = alarm_fields['metric']

    # alarm state and type
    alarm_type = alarm_fields['alert_type']

    if alarm_data['NewStateValue'] == "OK":
        alarm_type = "OK"

    # alarm title
    alarm_title = "{env} {app} {svc} {mtr_name} state changed to {a_type}".format(
        env=environment_name,
        app=application,
        svc=service,
        mtr_name=metric,
        a_type=alarm_type
    )

    # text body
    alarm_text = {
        'metric': alarm_data['Trigger']['MetricName'],
        'service': alarm_data['Trigger']['Namespace'],
        'id': alarm_data['Trigger']['Dimensions'][0]['value'],
        'info': alarm_data['AlarmDescription']
    }

    # slack message fields
    message_obj = {
        'text': alarm_text,
        'title': alarm_title.upper(),
        'emoji_type': alarm_type.lower()
    }
    logger.debug({
        'message': {
            'variables': {
                'alarm_text': alarm_text,
                'alarm_type': alarm_type,
                'alarm_data': alarm_data
            }
        }
    })
    logger.info({
        'message': {
            'variable': 'message_obj',
            'value': message_obj
        }
    })

    # call message handler
    result = message_handler(message_obj)
    logger.info({
        'message': {
            'variable': 'message_handler',
            'value': result
        }
    })

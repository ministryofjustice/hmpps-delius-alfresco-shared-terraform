import slack
import json

from app.config import Config
from app.ssm_handler import SSM_Handler
from app.logging_handler import get_logger

# setup logging
logger = get_logger()

# get token from ssm
ssm_handler = SSM_Handler()
get_token = ssm_handler.get_parameter(Config.slack_api_token)
token = None
if get_token['status'] == "success":
    token = get_token['Value']


class Slack_Handler():
    def __init__(self):
        self.slack_token = token
        self.slack_channel_name = Config.slack_channel_name
        self.client = slack.WebClient(token=self.slack_token)
        self.emoji_types = {
            'alert': Config.slack_emoji_alert,
            'critical': Config.slack_emoji_critical,
            'warning': Config.slack_emoji_warning,
            'ok': Config.slack_emoji_ok
        }

    def send_message(self, content_obj):
        emoji = self.emoji_types[content_obj['emoji_type']]
        icon_emoji = ":{}:".format(emoji)
        title = content_obj['title']
        alarm_text = content_obj['text']
        response = self.client.chat_postMessage(
            channel="delius-alerts-alfresco-nonprod",
            username="AWS Lambda",
            blocks=[
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*{}*".format(title)
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Alert State*"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Metric*"
                        },
                        {
                            "type": "plain_text",
                            "text": "{}".format(icon_emoji)
                        },
                        {
                            "type": "plain_text",
                            "text": alarm_text['metric']
                        },
                    ]
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": alarm_text['description']
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Service*"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*ID*"
                        },
                        {
                            "type": "plain_text",
                            "text": alarm_text['service']
                        },
                        {
                            "type": "plain_text",
                            "text": alarm_text['id']
                        }
                    ]
                }
            ]
        )
        logger.debug({
            'message': {
                'function': 'send_message',
                'variables': {
                    'text': alarm_text,
                    'emoji': emoji,
                    'title': title,
                    'channel': self.slack_channel_name
                }
            }
        })
        return response

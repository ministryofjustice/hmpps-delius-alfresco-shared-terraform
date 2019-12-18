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
        message_text = json.dumps(
            content_obj['text'], sort_keys=True, indent=4)
        text_body = '{} *{}* {}'.format(
            icon_emoji,
            title,
            message_text
        )
        response = self.client.chat_postMessage(
            channel=self.slack_channel_name,
            text=text_body
        )
        logger.debug({
            'message': {
                'text': text_body,
                'function': 'send_message',
            }
        })
        return response

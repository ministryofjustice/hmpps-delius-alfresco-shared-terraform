import slack

from app.config import Config
from app.aws.ssm_handler import SSM_Handler

ssm_handler = SSM_Handler()
get_token = ssm_handler.get_parameter(Config.slack_api_token)
if get_token['success']:
    token = get_token['Value']

class Slack_Handler():
    def __init__(self):
        self.slack_token = token
        self.slack_channel_name = Config.slack_channel_name
        self.client = slack.WebClient(token=self.slack_token)
        self.channel_id = None
        self.emoji_types = {
            'alarm': Config.slack_emoji_alarm,
            'ok': Config.slack_emoji_ok
        }

    def get_channel_id(self):
        response = self.client.channels_list()
        if response.status_code == 200:
            _channel = {'id': channel['id'] for channel in response.data['channels']
                        if channel['name'] == self.slack_channel_name}
            self.channel_id = _channel['id']
            return True
        return False

    def send_message(self, content_obj):
        response = {
            'message': 'message not sent'
        }
        if self.get_channel_id():
            emoji = self.emoji_types[content_obj['emoji_type']]
            title = content_obj['title']
            text = content_obj['text']
            response = self.client.chat_postMessage(
                channel=self.channel_id,
                text=':{}: *{}* - {}'.format(
                    emoji,
                    title,
                    text
                )
            )
        return response

import os


class Config():
    environment_name = os.environ.get("ENVIRONMENT_NAME", "dev")
    aws_region = os.environ.get("AWS_DEFAULT_REGION", "eu-west-2")
    slack_messaging_status = os.environ.get(
        "SLACK_MESSAGING_STATUS", "disabled")
    log_level = os.environ.get("LOG_LEVEL", "INFO")
    slack_api_token = os.environ.get("SLACK_API_TOKEN_SSM")
    slack_channel_name = os.environ.get("SLACK_CHANNEL_NAME")
    slack_emoji_critical = os.environ.get("SLACK_EMOJI_CRITICAL", "alert")
    slack_emoji_alert = os.environ.get("SLACK_EMOJI_ALERT", "rotating_light")
    slack_emoji_warning = os.environ.get("SLACK_EMOJI_WARNING", "warning")
    slack_emoji_ok = os.environ.get(
        "SLACK_EMOJI_OK", "white_check_mark")

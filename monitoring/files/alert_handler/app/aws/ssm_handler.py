import boto3

from app.config import Config
from app.logging_handler import get_logger

# setup logging
logger = get_logger()

class SSM_Handler():
    def __init__(self):
        self.region = Config.aws_region
        self.ssm_client = boto3.client(
            'ssm',
            region_name=self.region
        )

    def get_parameter(self, name):
        resp_obj = {
           'status': 'failed',
           'message': 'not found'
        }
        try:
            response = self.ssm_client.get_parameter(
                Name=name,
                WithDecryption=True
            )
            if 'Parameter' in response:
                param_value = response['Parameter']['Value']
                resp_obj['status'] = 'success'
                resp_obj['message'] = 'Found ssm parameter arn - {}'.format(response['Parameter']['ARN'])
                logger.info(resp_obj)
                return param_value
        except self.ssm_client.exceptions.ParameterNotFound as err:
            resp_obj['message'] = err
            logger.debug(resp_obj)
            return resp_obj
        except Exception as err:
            resp_obj['message'] = err
            logger.debug(resp_obj)
            return resp_obj

import os


environment = os.environ.get('APP_ENVIRONMENT', 'dev')


class BaseConfig:
    """Base configuration"""
    TESTING = False
    es_host = os.environ.get('ES_HOST', 'localhost')
    repository_path = os.environ.get('ES_REPO_PATH', '/opt/es_backups')
    repository_name = os.environ.get('ES_REPO_NAME', 'SR2_Backup')
    request_timeout = int(os.environ.get('ES_REQUEST_TIMEOUT', 120))


class DevelopmentConfig(BaseConfig):
    """Development configuration"""
    pass


class TestingConfig(BaseConfig):
    """Testing configuration"""
    TESTING = True
    es_host = os.environ.get('ES_HOST', 'elasticsearch')
    repository_name = 'test'
    request_timeout = int(1)


class ProductionConfig(BaseConfig):
    """Production configuration"""
    request_timeout = int(os.environ.get('ES_REQUEST_TIMEOUT', 60))


if environment == 'dev':
    Config = DevelopmentConfig
elif environment == 'test':
    Config = TestingConfig
elif environment == 'prod':
    Config = ProductionConfig
else:
    raise ValueError('Invalid environment name')

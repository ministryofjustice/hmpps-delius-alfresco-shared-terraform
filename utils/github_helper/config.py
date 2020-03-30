# utils/github_helper/config.py

import os


class GitHub_Config():
    def __init__(self):
        self.github_org = os.environ.get("GITHUB_ORG")
        self.github_api_url = "https://api.github.com"
        self.github_user = os.environ.get("HMPPS_GITHUB_USER")
        self.github_token = os.environ.get("HMPPS_GITHUB_TOKEN")
        self.github_repo = os.environ.get("GITHUB_REPO")
        self.req_headers = {
            'Authorization': f'token {self.github_token}'
        }
        self.release_pipeline = os.environ.get("RELEASE_PIPELINE")
        self.repo_url = f"{self.github_api_url}/repos/{self.github_org}/{self.github_repo}"

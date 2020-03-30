import requests
import json
import semver

from typing import Dict
from requests.exceptions import HTTPError


def request_handler(request_data: Dict):
    """
    Handles all requests

    Parameters:
        method (str): http method ('POST', 'GET', 'DELETE')
        url (str): request url
        headers (dict): headers to be used as part of request
        data (dict): json data sent as part of the request

    Returns:
        dict: request response
    """
    req_headers = request_data["headers"]
    req_method = request_data["method"]
    req_url = request_data["url"]

    try:
        if req_method == "GET":
            response = requests.get(
                req_url,
                headers=req_headers
            )

        if req_method == "POST":
            data = request_data["data"]
            response = requests.post(
                req_url,
                headers=req_headers,
                data=json.dumps(data)
            )

        if req_method == "DELETE":
            response = requests.delete(
                req_url,
                headers=req_headers
            )

        if response:
            return response
    except HTTPError as http_err:
        print(
            f"HTTP error occurred using {req_method} to address {req_url} : {http_err}")
        return None
    except Exception as err:
        print(
            f"Unknown error occurred using {req_method} to address {req_url} : {err}")
        return None
    else:
        return None


def generate_version(version: str):
    """
    Generates a new version using semver  

    Parameters:
        version (str): version to parse

    Returns:
        string: new version number
    """
    try:
        parsed_version = semver.parse_version_info(version)
        new_version = parsed_version.bump_patch()
        updated_version = semver.replace(version, patch=new_version.patch)
        return updated_version
    except Exception as err:
        return err

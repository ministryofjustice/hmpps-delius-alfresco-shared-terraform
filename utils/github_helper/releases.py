# utils/github_helper/tag_handler.py

from github_helper.config import GitHub_Config
from github_helper.handlers import request_handler, generate_version


class Release_Handler(GitHub_Config):
    """
    GitHub tag handler
    """

    def __init__(self):
        GitHub_Config.__init__(self)
        self.release_details = None
        self.current_release = None
        self.tag_details = None
        self.create_release_status = False


    def get_commit_ids(self):
        request_data = {
            "method": "GET",
            "headers": self.req_headers,
            "url": f"{self.repo_url}/commits"
        }
        response = request_handler(request_data)
        commit_ids = [id["sha"] for id in response.json()]
        return commit_ids

    def get_latest_version(self):
        """
        Retrieves information about a tag

        Parameters:
            release_name (str): tag name

        Returns:
            dict: tag details
        """
        try:
            request_data = {
                "method": "GET",
                "headers": self.req_headers,
                "url": f"{self.repo_url}/releases/latest"
            }
            response = request_handler(request_data)
            if response is None:
                return {
                    "message": "No releases found",
                    "status_code": 404
                }
            if response.status_code == 200 and 'tag_name' in response.json():
                self.current_release = response.json()
                return self.current_release['tag_name']
            return response

        except Exception as err:
            print("Error occurred getting tag: {}".format(err))
            return None
        else:
            return None

    def get_tag(self, tag_name: str):
        """
        Retrieves information about a tag

        Parameters:
            tag_name (str): branch name

        Returns:
            dict: Tag information
        """
        try:
            request_data = {
                "method": "GET",
                "headers": self.req_headers,
                "url": f"{self.repo_url}/git/ref/tags/{tag_name}"
            }
            response = request_handler(request_data)

            if response is None:
                return None

            if response.status_code == 200:
                self.tag_details = response.json()
                return response.json()

            return self.tag_details

        except Exception as err:
            print("Error occurred getting tag: {}".format(err))
            return None
        else:
            return None
    
    def create_alpha_tag(self):
        _file = "configs/package.properties"
        src_file = open(_file, "rt")
        data = src_file.read()
        data = data.replace("no", "yes")
        src_file.close()
        target_file = open(_file, "wt")
        target_file.write(data)
        target_file.close()
        return None

    def create_release(self, branch_name: str, commit_id: str):
        """
        Create a release

        Parameters:
            branch_name (str): Specifies the git branch tag is created from.
            commit_id (str): git commit id


        Returns:
            dict: tag details
        """
        try:
            current_version = self.get_latest_version()
            release_name = generate_version(current_version)
            resp_obj = {
                "message": f"Error occurred creating release version {release_name} no changes made",
                "exit_code": 1
            }

            current_tag = self.get_tag(current_version)

            if current_tag is not None:
                if current_tag['object']["sha"] != commit_id:
                    _ids = self.get_commit_ids()
                    if commit_id in _ids:
                        self.create_release_status = True

            if self.create_release_status == False:
                resp_obj['message'] = f"Release {current_version} using commit id {commit_id}, skipping creating new release"
                resp_obj['exit_code'] = 0
                resp_obj['data'] = self.tag_details
                return resp_obj

            url = f"{self.repo_url}/releases"
            req_body = {
                "tag_name": release_name,
                "target_commitish": branch_name,
                "name": release_name,
                "draft": False,
                "prerelease": False
            }

            request_data = {
                "method": "POST",
                "headers": self.req_headers,
                "url": url,
                "data": req_body
            }

            response = request_handler(request_data)

            if response.json() is not None and response.status_code == 201:
                self.create_alpha_tag()
                self.release_details = response.json()
                resp_obj['message'] = f"Release {release_name} created using branch {branch_name}"
                resp_obj['exit_code'] = 0
                resp_obj['data'] = self.release_details
                return resp_obj
            return response
        except Exception as err:
            print("Error occurred creating tag: {}".format(err))
            resp_obj['message'] = f"An error occurred creating release {release_name}"
            resp_obj['error'] = err
            return resp_obj
        else:
            return None

    def get_release_commit_id(self):
        current_version = self.get_latest_version()
        current_tag = self.get_tag(current_version)

        if current_tag is not None:
            return current_tag['object']["sha"]
        return None

    def task_handler(self, branch_name: str, commit_id: str):
        resp_obj = {
            "message": "no task completed",
            "exit_code": 1
        }
        result = self.create_release(branch_name, commit_id)
        if result is not None:
            resp_obj = result
            return resp_obj

        resp_obj['error'] = result
        return resp_obj

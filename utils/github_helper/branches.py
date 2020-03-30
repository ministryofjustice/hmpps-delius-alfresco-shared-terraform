# utils/github_helper/branch_handler.py

from github_helper.config import GitHub_Config
from github_helper.handlers import request_handler
from github_helper.releases import Release_Handler


class Branch_Handler(GitHub_Config):
    """
    GitHub branch handler
    """

    def __init__(self):
        GitHub_Config.__init__(self)
        self.branch_details = None

    def get_branch(self, branch_name: str):
        """
        Retrieves information about a branch

        Parameters:
            branch_name (str): branch name

        Returns:
            dict: branch details
        """
        try:
            request_data = {
                "method": "GET",
                "headers": self.req_headers,
                "url": f"{self.repo_url}/git/ref/heads/{branch_name}"
            }
            response = request_handler(request_data)
            if response is None:
                return {
                    "message": "branch not found",
                    "status_code": 404
                }
            if response.status_code == 200:
                self.branch_details = response.json()
            return self.branch_details

        except Exception as err:
            print("Error occurred getting branch: {}".format(err))
            return None
        else:
            return None

    def check_branch(self, branch_name: str):
        self.get_branch(branch_name)
        if self.branch_details is None:
            return False
        return True

    def create_branch(self, branch_name: str, commit_id: str):
        """
        Create a branch

        Parameters:
            branch_name (str): branch name
            commit_id (str): SHA1 value of git commit id to use


        Returns:
            dict: branch details
        """
        try:
            resp_obj = {
                "message": f"Error occurred, {branch_name} no changes made",
                "exit_code": 1
            }
            if self.check_branch(branch_name):
                if self.branch_details['object']['sha'] == commit_id:
                    resp_obj['message'] = f"{branch_name} branch current sha {commit_id}, no changes needed"
                    resp_obj['exit_code'] = 0
                    return resp_obj
                self.delete_branch(branch_name)

            url = f"{self.repo_url}/git/refs"
            req_body = {
                "ref": f"refs/heads/{branch_name}",
                "sha": f"{commit_id}"
            }

            request_data = {
                "method": "POST",
                "headers": self.req_headers,
                "url": url,
                "data": req_body
            }

            response = request_handler(request_data)

            if response.json() is not None and (response.status_code == 201 or response.status_code == 200):
                self.branch_details = response.json()
                resp_obj['message'] = f"{branch_name} branch created with commit-id {commit_id}"
                resp_obj['exit_code'] = 0
                resp_obj['data'] = self.branch_details
                return resp_obj
            return response
        except Exception as err:
            print("Error occurred creating branch: {}".format(err))
            return None
        else:
            return None

    def delete_branch(self, name: str):
        """
        Deletes a branch

        Parameters:
            name (str): branch name

        Returns: 
            dict: {"message" "success", "status_code", 204}
        """
        try:
            resp_obj = {
                "message": "failed",
                "status_code": 404,
                "error": "branch not found"
            }
            self.get_branch(name)
            if self.branch_details is None:
                return resp_obj

            request_data = {
                "method": "DELETE",
                "headers": self.req_headers,
                "url": self.branch_details['url']
            }

            response = request_handler(request_data)
            if response.status_code == 204:
                resp_obj['message'] = "success"
                resp_obj['status_code'] = response.status_code
            return resp_obj

        except Exception as err:
            print("Other error occurred deleting branch: {}".format(err))
            return None
        else:
            return None

    def task_handler(self, branch_name: str):
        resp_obj = {
            "message": "no task completed",
            "exit_code": 1
        }
        release_mgr = Release_Handler()
        commit_id = release_mgr.get_release_commit_id()

        result = self.create_branch(branch_name, commit_id)
        if self.branch_details is not None:
            resp_obj = result
            return resp_obj

        resp_obj['error'] = result
        return resp_obj

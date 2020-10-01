import requests
import json

es_host = "https://localhost:8443" # tunnel endpoint
snapshot_name = "es_snapshot-2020_9_30_12_4"
repo_name = "es_snapshot_repo"
indices = [ "alfresco-logstash-2020.02.07", "alfresco-logstash-2020.05.11"]

work_list = [index for index in indices if "2020" in index] # filter by string
work_list
req_body = {
  "indices": work_list
}

url = f"{es_host}/_snapshot/{repo_name}/{snapshot_name}"
headers = {"Content-Type": "application/json"}
restore_url = f"{url}/_restore"
r = requests.post(restore_url, verify=False, data=json.dumps(req_body), headers=headers)
print(r.json())

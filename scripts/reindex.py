from jinja2 import Environment, FileSystemLoader

from app.helpers import string_replacer
from app.helpers import json_dumper

from app.elasticsearch_app.indices import Elasticsearch_Indices_Handler
from app.elasticsearch_app.snapshot import Elasticsearch_Snapshot_Handler

import os

es_snapshot = Elasticsearch_Snapshot_Handler()
es_indices = Elasticsearch_Indices_Handler()

src_index = 'alfresco-logstash'
indices = es_indices.get_indices_matching_pattern(src_index)

template_file = os.environ.get('REINDEX_TEMPLATE', 'reindex.sh.tmpl')
scripts_dir = os.environ.get("SCRIPT_DIR", '/opt/scripts')
output_file_name = os.environ.get('REINDEX_SHELL_SCRIPT')
output_file = "{}/{}".format(scripts_dir, output_file_name)
file_loader = FileSystemLoader('{}/templates'.format(scripts_dir))
env = Environment(loader=file_loader)

template = env.get_template(template_file)
output = template.render(indices=indices)

with open(output_file, 'a') as the_file:
    the_file.write(output)

print('done')

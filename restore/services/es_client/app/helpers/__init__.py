import json


def string_replacer(pattern):
    if type(pattern) is tuple and len(pattern) == 3:
        text_string = pattern[0]
        characters_old = pattern[1]
        characters_new = pattern[2]
        output = text_string.replace(characters_old, characters_new)
        return output
    else:
        return False


def json_dumper(json_data, operation=None):
    if operation is not None:
        json_data.update({'operation': operation})
    return json.dumps(json_data, indent=4, sort_keys=True)

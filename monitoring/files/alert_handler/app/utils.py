def alarm_formatter(payload):
    alarm_obj = {}
    fields = payload.split('_')
    alarm_obj['application'] = fields[0]
    alarm_obj['service'] = fields[1]
    alarm_obj['metric'] = fields[2]
    alarm_obj['alert_type'] = fields[3]
    return alarm_obj

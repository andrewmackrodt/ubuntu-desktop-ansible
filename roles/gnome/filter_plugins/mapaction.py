def mapaction(enable):
    if enable:
        return 'enable'
    else:
        return 'disable'


class FilterModule(object):
    def filters(self):
        return {'mapaction': mapaction}

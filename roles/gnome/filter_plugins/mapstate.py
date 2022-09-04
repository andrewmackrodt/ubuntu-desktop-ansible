def mapstate(enable):
    if enable:
        return 'ENABLED'
    else:
        return 'INITIALIZED|DISABLED'


class FilterModule(object):
    def filters(self):
        return {'mapstate': mapstate}

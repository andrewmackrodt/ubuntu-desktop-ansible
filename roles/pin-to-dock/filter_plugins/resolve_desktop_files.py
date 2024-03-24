import re


def find_in_list(pattern, search):
    pattern = pattern.replace('.', '\\.').replace('*', '.*')
    for compare in search:
        if re.match(fr'^{pattern}$', compare):
            return compare
    return None


def resolve_desktop_files(apps, available):
    res = []
    for app in apps:
        name = app['name'].replace('*', '')
        item = find_in_list(app['name'], available)
        if item:
            res.append(item)
        elif 'fallback' in app and len(app['fallback']):
            for fallback in app['fallback']:
                item = find_in_list(fallback, available)
                if item:
                    res.append(item)
                    break
        else:
            res.append(name)
    return res


class FilterModule(object):
    def filters(self):
        return {'resolve_desktop_files': resolve_desktop_files}

def resolve_desktop_files(apps, available):
    res = []
    for app in apps:
        if app['name'] in available:
            res.append(app['name'])
        elif 'fallback' in app and len(app['fallback']):
            for item in app['fallback']:
                if item in available:
                    res.append(item)
                    break
        else:
            res.append(app['name'])
    return res


class FilterModule(object):
    def filters(self):
        return {'resolve_desktop_files': resolve_desktop_files}

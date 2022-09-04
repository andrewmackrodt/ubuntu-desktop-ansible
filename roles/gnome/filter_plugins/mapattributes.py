def mapattributes(list_of_dicts, list_of_keys):
    res = []
    for item in list_of_dicts:
        filtered = {}
        for key in list_of_keys:
            filtered[key] = item[key]
        res.append(filtered)
    return res


class FilterModule(object):
    def filters(self):
        return {'mapattributes': mapattributes}

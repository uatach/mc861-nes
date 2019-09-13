import attr

@attr.s
class NES(object):
    def run(self, data):
        print('running...')
        print(len(data))

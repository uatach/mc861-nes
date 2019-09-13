import attr


@attr.s
class NES(object):
    cpu = attr.ib()

    def run(self, data):
        print("running...")
        print(len(data))

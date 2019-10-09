import attr


@attr.s
class Register(object):
    size = attr.ib(8)
    value = 0

    def __get__(self, obj, type=None):
        return self.value

    def __set__(self, obj, value):
        self.value = value

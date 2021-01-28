import argparse


PREFLIGHT_PLUGINS = {}


class Command(object):

    def __init__(self, name, arguments):
        self.name = name
        self.arguments = arguments
        def dummy_preflight(*args, **kwargs):
            pass
        self.preflight_callback = dummy_preflight

    def perform_preflight(self, container, args):
        parser = argparse.ArgumentParser(add_help=False)
        parser.add_argument("--port", "-p", default=8000)
        options, unknown = parser.parse_known_args(args)
        self.preflight_callback(container, options)


class Argument(object):

    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs

    def bind(self, parser):
        parser.add_argument(*(self.argument.args), **(self.argument.kwargs))


def preflight_plugin(name, arguments=[]):
    """
    Register a new preflight plugin.
    """
    def decorator(f):
        command = Command(name, arguments)
        command.preflight_callback = f
        PREFLIGHT_PLUGINS[name] = command
        return f
    return decorator

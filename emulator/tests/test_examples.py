import os
import pytest

from src import cli
from click.testing import CliRunner


def get_filenames(directory):
    for dirpath, _, filenames in os.walk(directory):
        for filename in sorted(filenames):
            yield filename, os.path.join(dirpath, filename)


def collect_examples():
    names = []
    outputs = []
    for filename, filepath in get_filenames("res/"):
        names.append(filename[:-2])
        outputs.append(filepath)

    inputs = []
    for filename, filepath in get_filenames("bin/"):
        if filename in names:
            inputs.append(filepath)

    for a, b in list(zip(sorted(inputs), sorted(outputs))):
        assert a.split("/")[-1] == b.split("/")[-1][:-2]
    return list(zip(sorted(inputs), sorted(outputs)))


def test_error():
    assert CliRunner().invoke(cli).exception


@pytest.mark.parametrize("inpath, outpath", collect_examples())
def test_example(inpath, outpath):
    """Runs test against a single file in the examples dir"""
    result = CliRunner().invoke(cli, [inpath])

    if result.exception:
        raise result.exception

    with open(outpath) as f:
        outlines = result.output.split("\n")
        inlines = f.read().split("\n")
        for i, (r, o) in enumerate(zip(outlines, inlines)):
            assert r == o, "wrong output at line {}".format(i)

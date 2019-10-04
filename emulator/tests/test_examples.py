import os
import pytest

from src import cli
from click.testing import CliRunner


def get_filenames(directory):
    for dirpath, _, filenames in os.walk(directory):
        for filename in sorted(filenames):
            yield filename, os.path.join(dirpath, filename)


def collect_examples():
    inputs = []
    for filename, filepath in get_filenames("bin/"):
        inputs.append(filepath)

    outputs = []
    for filename, filepath in get_filenames("res/"):
        outputs.append(filepath)

    assert len(inputs) == len(outputs), 'the number of tests do not match the number of outputs'
    for a, b in list(zip(sorted(inputs), sorted(outputs))):
        assert a.split("/")[-1] == b.split("/")[-1][:-2], 'expected tests names do not match'
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

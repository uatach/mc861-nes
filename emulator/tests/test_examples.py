import os
import pytest

from src import cli
from click.testing import CliRunner


def collect_examples():
    inputs = []
    for dirpath, dirnames, filenames in os.walk("bin/"):
        for filename in sorted(filenames):
            inputs.append(os.path.join(dirpath, filename))
    outputs = []
    for dirpath, dirnames, filenames in os.walk("res/"):
        for filename in sorted(filenames):
            outputs.append(os.path.join(dirpath, filename))
    return list(zip(inputs, outputs))


def test_error():
    assert CliRunner().invoke(cli).exception


@pytest.mark.parametrize("inpath, outpath", collect_examples())
def test_example(inpath, outpath):
    """Runs test against a single file in the examples dir"""
    result = CliRunner().invoke(cli, [inpath])

    if result.exception:
        raise result.exception

    with open(outpath) as f:
        assert result.output == f.read()

from setuptools import setup, find_packages

import src as pynesemu

setup(
    name=pynesemu.__name__,
    version=pynesemu.__version__,
    author="Group13",
    url="https://gitlab.ic.unicamp.br/ra156737/mc861-nes",
    include_package_data=True,
    packages=find_packages(),
    install_requires=["attrs>=18.1", "click>=6.7", "pygame>=1.9.6"],
    license="MIT",
    entry_points={"console_scripts": ["pynesemu = src.main:cli"]},
)

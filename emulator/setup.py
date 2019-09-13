from setuptools import setup, find_packages

import src as pynesemu

setup(
    name=pynesemu.__name__,
    version=pynesemu.__version__,
    author="Group13",
    url="",
    include_package_data=True,
    packages=find_packages(),
    install_requires=["attrs>=18.1", "click>=6.7"],
    license="MIT",
    entry_points={"console_scripts": ["pynesemu = src.main:cli"]},
)

from setuptools import setup, find_packages
from codecs import open
from os import path

import spinegeneric

# Get the directory where this current file is saved
here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

req_path = path.join(here, 'requirements.txt')
with open(req_path, "r") as f:
    install_reqs = f.read().strip()
    install_reqs = install_reqs.split("\n")

setup(
    name='spinegeneric',
    version=spinegeneric.__version__,
    python_requires='>=3.7,<3.11',
    description='Collection of cli to process data for the Spine Generic project.',
    url='https://spine-generic.rtfd.io',
    author='NeuroPoly Lab, Polytechnique Montreal',
    author_email='neuropoly@googlegroups.com',
    license='MIT',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
    ],
    keywords='',
    install_requires=install_reqs,
    packages=find_packages(exclude=['.git', '.github', '.docs']),
    include_package_data=True,
    package_data={
        '': ['*.png', '*.json', '*.r'],
    },
    entry_points={
        'console_scripts': [
            'sg_copy_to_derivatives = spinegeneric.cli.copy_to_derivatives:main',
            'sg_create_mosaic = spinegeneric.cli.create_mosaic:main',
            'sg_deface_using_r = spinegeneric.cli.deface_spineGeneric_usingR:main',
            'sg_generate_figure = spinegeneric.cli.generate_figure:main',
            'sg_manual_correction = spinegeneric.cli.manual_correction:main',
            'sg_package_for_correction = spinegeneric.cli.package_for_correction:main',
            'sg_populate_derivatives = spinegeneric.cli.populate_derivatives:main',
            'sg_qc_bids_deface = spinegeneric.cli.qc_bids_deface:main',
            'sg_params_checker = spinegeneric.cli.params_checker:main',
            'sg_check_data_consistency = spinegeneric.cli.check_data_consistency:main'
        ],
    },
)

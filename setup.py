import os
from setuptools import find_packages, setup

try:
    readme = open(os.path.join(os.path.dirname(__file__), "README.rst")).read()
except OSError:
    readme = ""

version = "0.2.8"

install_requires = [
    "Django",
    "packaging",
]

tests_require = [
    "Django",
]

setup(
    name="django-nine-v2",
    version=version,
    description="Version checking library.",
    long_description="{0}".format(readme),
    python_requires=">=3.11",
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Environment :: Web Environment",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "License :: OSI Approved :: GNU Lesser General Public License v2 or "
        "later (LGPLv2+)",
        "Framework :: Django",
        "Framework :: Django :: 4.0",
        "Framework :: Django :: 4.1",
        "Framework :: Django :: 4.2",
        "Framework :: Django :: 5.0",
        "Framework :: Django :: 5.1",
        "Framework :: Django :: 5.2",
        "Framework :: Django :: 6.0",
        "Intended Audience :: Developers",
        "Operating System :: OS Independent",
        "Development Status :: 5 - Production/Stable",
    ],
    project_urls={
        "Bug Tracker": "https://github.com/JahanzebNawaz/django-nine-v2/issues",
        "Documentation": "https://github.com/JahanzebNawaz/django-nine-v2#readme",
        "Source Code": "https://github.com/JahanzebNawaz/django-nine-v2",
        "Changelog": "https://github.com/JahanzebNawaz/django-nine-v2/blob/main/CHANGELOG.rst",
    },
    keywords="django, compatibility",
    author="Artur Barseghyan",
    author_email="artur.barseghyan@gmail.com",
    maintainer="Jahanzeb Nawaz",
    maintainer_email="mr.njahanzeb@gmail.com",
    url="https://github.com/JahanzebNawaz/django-nine-v2/",
    package_dir={"": "src"},
    packages=find_packages(where="./src"),
    license="GPL-2.0-only OR LGPL-2.1-or-later",
    install_requires=install_requires,
    tests_require=tests_require,
    package_data={},
    include_package_data=True,
)

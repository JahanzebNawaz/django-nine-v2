====================
django-nine-v2
====================
`django-nine-v2` - version checking library for Django.

.. image:: https://img.shields.io/pypi/v/django-nine-v2.svg
   :target: https://pypi.python.org/pypi/django-nine-v2
   :alt: PyPI Version

.. image:: https://img.shields.io/pypi/pyversions/django-nine-v2.svg
    :target: https://pypi.python.org/pypi/django-nine-v2/
    :alt: Supported Python versions

.. image:: https://github.com/JahanzebNawaz/django-nine-v2/actions/workflows/test.yml/badge.svg
   :target: https://github.com/JahanzebNawaz/django-nine-v2/actions/workflows/test.yml
   :alt: Build Status

.. image:: https://readthedocs.org/projects/django-nine-v2/badge/?version=latest
    :target: https://django-nine-v2.readthedocs.io/en/latest/?badge=latest
    :alt: Documentation Status

.. image:: https://img.shields.io/badge/license-GPL--2.0--only%20OR%20LGPL--2.1--or--later-blue.svg
   :target: https://github.com/JahanzebNawaz/django-nine-v2/#License
   :alt: GPL-2.0-only OR LGPL-2.1-or-later

.. image:: https://coveralls.io/repos/github/JahanzebNawaz/django-nine-v2/badge.svg?branch=master
    :target: https://coveralls.io/github/JahanzebNawaz/django-nine-v2?branch=master
    :alt: Coverage

Prerequisites
=============
- Python 3.7, 3.8, 3.9, 3.10. 3.11, 3.12, 3.13 
- Django 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 2.0, 2.1, 2.2, 3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, and 5.2

Documentation
=============
Documentation is available on `Read the Docs
<https://django-nine-v2.readthedocs.io/>`_.

Installation
============
Install latest stable version from PyPI:

.. code-block:: sh

    pip install django-nine-v2

Or latest stable version from GitHub:

.. code-block:: sh

    pip install git+https://github.com/JahanzebNawaz/django-nine-v2.git

Usage
=====
Get Django versions
-------------------
In code
~~~~~~~
For example, if Django version installed in your environment is 1.7.4, then
the following would be true.

.. code-block:: python

    from django_nine import versions

    versions.DJANGO_1_7  # True
    versions.DJANGO_LTE_1_7  # True
    versions.DJANGO_GTE_1_7  # True
    versions.DJANGO_GTE_1_8  # False
    versions.DJANGO_GTE_1_4  # True
    versions.DJANGO_LTE_1_6  # False

In templates
~~~~~~~~~~~~
With use of context processors
##############################
Add ``nine.context_processors.versions`` to your context processors.

.. code-block:: python

    TEMPLATES[0]['OPTIONS']['context_processors'] += \
        ['django_nine.context_processors.versions']

Or if you are using an old version of Django:

.. code-block:: python

    TEMPLATE_CONTEXT_PROCESSORS += ['django_nine.context_processors.versions']

Testing
=======
Simply type:

.. code-block:: sh

    ./runtests.py

Or use tox:

.. code-block:: sh

    tox

Or use tox to check specific env:

.. code-block:: sh

    tox -e py37

Or run Django tests:

.. code-block:: sh

    ./manage.py test nine --settings=settings.testing

License
=======
GPL-2.0-only OR LGPL-2.1-or-later

Support
=======
For any security issues contact me at the e-mail given in the `Author`_ section.
For overall issues, go to `GitHub <https://github.com/JahanzebNawaz/django-nine-v2/issues>`_.

Author
======
Jahanzeb Nawaz <mr.njahanzeb@gmail.com>

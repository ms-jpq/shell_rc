#!/usr/bin/env python3

import pkg_resources
import subprocess

packages = [dist.project_name for dist in pkg_resources.working_set]
install = f"pip3 install --upgrade {' '.join(packages)}"

subprocess.call(install.split())

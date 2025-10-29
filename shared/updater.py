#!/usr/bin/env python3

import os, sys
from configparser import ConfigParser, ExtendedInterpolation
import requests
from packaging import version

script_dir = os.path.dirname(os.path.abspath(__file__))

# Allow to interpolate section names
class MyExtendedInterpolation(ExtendedInterpolation):
	def before_get(self, parser, section, option, value, defaults):
		defaults.maps.append({'section': section})
		return super().before_get(parser, section, option, value, defaults)

ini_file = "packages.ini"
pr_file = "pr-body.txt"

def query_anitya(id):
	url = 'https://release-monitoring.org/api/project/'
	headers = { 'Accept': 'application/json' }
	response = requests.get(url=url + str(id), headers=headers)

	if not response:
		print("Error querying Anitya!")
		return None
	return response.json()["stable_versions"][0]


if __name__ == '__main__':
	cp = ConfigParser(interpolation=MyExtendedInterpolation())

	try:
		with open(f"{script_dir}/{ini_file}", 'r') as f:
			cp.read_file(f)
	except EnvironmentError:
		print(f"Error reading '{ini_file}' file!")
		sys.exit(1)

	# check for updates
	version_map = {}
	for lib in cp.sections():
		if not cp.has_option(lib, "anitya_id"):
			print(f"Skipping {lib}, no Anitya id.")
			continue
		else:
			print(f"Checking {lib}: ", end='')
		ver = query_anitya(cp.getint(lib, "anitya_id"))
		if ver:
			print(f"{ver}")
			version_map[lib] = ver

	print("Updating: ", end='')
	updates = []
	comma = ""
	for lib, ver in version_map.items():
		old_ver = cp.get(lib, "version")
		if version.parse(ver) <= version.parse(old_ver):
			continue
		else:
			print(f"{comma}{lib}", end='')
			comma = ", "
		# check for special handling
		if cp.has_option(lib, "version_major"):
			v = ver.split(".") # expat
			if v[0] == ver:
				v = ver.split("-") # ICU
			cp.set(lib, "version_major", v[0])
			if cp.has_option(lib, "version_minor"):
				cp.set(lib, "version_minor", v[1])
				if cp.has_option(lib, "version_patch"):
					cp.set(lib, "version_patch", v[2])
		else:
			cp.set(lib, "version", ver)
		updates.append(f" - **{lib}**: {old_ver} → {ver}")
	print()

	try:
		with open(f"{script_dir}/{ini_file}", 'w') as f:
			cp.write(f)
	except EnvironmentError:
		print(f"Error writing '{ini_file}' file!")
		sys.exit(1)

	# generate pull request body
	if os.getenv('GITHUB_ACTIONS', "false") == "true":
		try:
			with open(f"{script_dir}/../{pr_file}", 'w') as f:
				f.write("The following libraries shall be updated:\n")
				f.write('\n'.join(updates))
				f.write("\n\nThis pull request will adapt to changes made in the repository.\n")
		except EnvironmentError:
			print(f"Error writing '{pr_file}' file!")
			sys.exit(1)

	print("All done.")

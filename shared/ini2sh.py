#!/usr/bin/env python3

import os, sys, re
from configparser import ConfigParser, ExtendedInterpolation

script_dir = os.path.dirname(os.path.abspath(__file__))

# Allow to interpolate section names
class MyExtendedInterpolation(ExtendedInterpolation):
	def before_get(self, parser, section, option, value, defaults):
		defaults.maps.append({'section': section})
		return super().before_get(parser, section, option, value, defaults)

# which .ini keys are present and how they are named in .sh file
LEGACY_MAP = {
	"url" : "URL",
	"directory" : "DIR",
	"files" : "FILES",
	"arguments" : "ARGS",
}
ini_file = "packages.ini"
shell_file = "packages.sh"

def make_prefix(s):
	# bash variables should only contain letters and underscore
	prefix = re.sub(r'\W+', '_', s, flags=re.A)
	prefix = prefix.upper()
	prefix += '_'
	return prefix

if __name__ == '__main__':
	cp = ConfigParser(interpolation=MyExtendedInterpolation())

	# load ini
	try:
		with open(f"{script_dir}/{ini_file}", 'r') as f:
			cp.read_file(f)
	except EnvironmentError:
		print(f"Error reading '{ini_file}' file!")
		sys.exit(1)

	original_stdout = sys.stdout

	# write to shell
	try:
		with open(f"{script_dir}/{shell_file}", 'w') as f:
			sys.stdout = f
			print("#!/bin/bash\n")
			print("##### GENERATED FILE, DO NOT EDIT! ####")
			print("# edit packages.ini and run ini2sh.py #")
			print("#######################################\n\n")

			# copy all ini sections
			for section in cp.sections():
				#print(f"#lib={section}")
				#version = cp.get(section, "version")
				#print(f"#ver={version}")
				prefix = make_prefix(section)
				for option in cp[section]:
					# shell comment
					if option == "comment":
						value = cp.get(section, option)
						print(f'# {value}')
					# skip unneeded
					if option not in LEGACY_MAP or not cp.get(section, option):
						continue
					param = LEGACY_MAP[option.lower()]
					value = cp.get(section, option)
					# arguments can span multiline
					if option == "arguments":
						value = value.replace("\n", " \\\n")
					print(f'{prefix}{param}={value}')
				print("")
			sys.stdout = original_stdout
	except EnvironmentError:
		print(f"Error writing '{shell_file}' file!")
		sys.exit(1)

	print("Done.")

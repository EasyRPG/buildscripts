#!/usr/bin/env python3

import os, sys
from pathlib import Path
import arrow, configargparse
from configparser import ConfigParser, ExtendedInterpolation
from urllib.parse import urlparse
from downloader_cli.download import Download

script_dir = os.path.dirname(os.path.abspath(__file__))

# Allow to interpolate section names
class MyExtendedInterpolation(ExtendedInterpolation):
	def before_get(self, parser, section, option, value, defaults):
		defaults.maps.append({'section': section})
		return super().before_get(parser, section, option, value, defaults)

ini_file = "packages.ini"

def args():
	p = configargparse.ArgParser(
		description="Downloads libraries.",
		epilog='Files will only be downloaded, when they do not exist.',
		formatter_class=configargparse.ArgumentDefaultsHelpFormatter)
	p.add('-d', '--directory', help='download directory', env_var='EASYRPG_PATH_DOWNLOADCACHE', default='download', type=Path)
	p.add('-c', '--clean', help='clean old files', action='store_true')
	p.add('-a', '--age', help='only clean up files older than AGE days', type=int, default=30)
	p.add('--no-confirm', help='do not ask before removing files', action='store_true')
	p.add('--no-download', help='do not download files (only do cleanup with -c)', action='store_true')
	p.add('-q', help='quiet', action='store_true')
	#p.add('lib', nargs='*', help='download only provided libraries', default=configargparse.SUPPRESS) # TODO

	config = p.parse_args()
	#print(p.format_values())
	return config

def get_download_links():
	# load ini
	ini = ConfigParser(interpolation=MyExtendedInterpolation())
	try:
		with open(f"{script_dir}/{ini_file}", 'r') as f:
			ini.read_file(f)
	except EnvironmentError:
		print(f"Error reading '{ini_file}' file!")
		sys.exit(1)

	# get download links
	links = []
	for lib in ini.sections():
		links.append(ini.get(lib, "url").strip('"'))

	#print(links)
	return links

def cleanup_dir(dir, age, confirm):
	now = arrow.now()
	to_delete = []

	for item in Path(dir).glob('*'):
		if item.is_file():
			item_time = arrow.get(item.stat().st_mtime).shift(days=age)
			if item_time < now:
				to_delete.append(item)
			#elif verbose:
			#	print(f"Skipping {item.name}")

	count = len(to_delete)
	if not count:
		if verbose:
			print("Not deleting, all files are recent.")
		return

	if confirm:
		print(f"You want to delete {count} file(s):")
		for item in to_delete:
			print(f"  {item.name}")
		if not input("Are you sure? (y/N) ").lower() == 'y':
			return

	for item in to_delete:
		item.unlink()

if __name__ == '__main__':
	config = args()
	#print(config)
	verbose = not config.q

	download_links = []
	download_count = 0
	if not config.no_download:
		temp_links = get_download_links()

		# check for already present files
		for link in temp_links:
			file = urlparse(link).path.rsplit("/", 1)[-1]
			if (config.directory / file).exists():
				# spare in cleanup
				(config.directory / file).touch()
			else:
				download_links.append(link)

		download_count = len(download_links)

		if verbose:
			present_count = len(temp_links) - download_count
			if present_count:
				print(f"Removed {present_count} download links, since files are already present.")

	# download remaining
	if download_count:
		print(f"Downloading {download_count} file(s) now:")
		for url in download_links:
			Download(url,
				des=config.directory,
				quiet=config.q or not sys.stdout.isatty()).download()
	elif verbose:
		print("No need to download files.")

	# cleanup
	if config.clean:
		cleanup_dir(config.directory, config.age, not config.no_confirm)

	if verbose:
		print("Done.")

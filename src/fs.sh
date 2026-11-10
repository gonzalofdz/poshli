#
# POSHLI - POSIX Shell Library
# File system checks module
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_FS_LOADED+x}" ]; then
_POSHLI_FS_LOADED=1

is_file() {
#	Returns 0 if the path exists and is a regular file.
#
#	Example of use:
#	is_file "$HOME/.profile" && echo "File exists" || echo "File does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -f "$1" ]
}

is_dir() {
#	Returns 0 if the path exists and is a directory.
#
#	Example of use:
#	is_dir "$HOME" && echo "Directory exists" || echo "Directory does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -d "$1" ]
}

is_readable() {
#	Returns 0 if the path exists and is readable.
#
#	Example of use:
#	is_readable "$HOME/.profile" && echo "File is readable" || echo "File is not readable"
#
	[ $# -ge 1 ] || return 2
	[ -r "$1" ]
}

is_writable() {
#	Returns 0 if the path exists and is writable.
#
#	Example of use:
#	is_writable "/tmp" && echo "Directory is writable" || echo "Directory is not writable"
#
	[ $# -ge 1 ] || return 2
	[ -w "$1" ]
}

is_exec() {
#	Returns 0 if the path exists and is executable.
#
#	Example of use:
#	is_exec "/bin/sh" && echo "File is executable" || echo "File is not executable"
#
	[ $# -ge 1 ] || return 2
	[ -x "$1" ]
}

is_empty_file() {
#	Returns 0 if the path is an existing regular file of size 0.
#
#	Example of use:
#	is_empty_file "/tmp/empty" && echo "File is empty" || echo "File is not empty or does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -f "$1" ] && [ ! -s "$1" ]
}

is_plain_text() {
#	Returns 0 if the path is a readable plain text file.
#
#	Example of use:
#	is_plain_text "$HOME/.profile" && echo "Plain text file" || echo "Not a plain text file"
#
	[ $# -ge 1 ] || return 2
	[ -r "$1" ] || return 1

	#	-b omits the file name so it cannot fool the 'text' match;
	#	LC_ALL=C keeps the description stable across locales.
	LC_ALL=C file -b "$1" | grep -q 'text'
}
fi

# shellcheck shell=sh
#
#  POSHLI - POSIX Shell Library
#  String manipulation and predicates module
#
#  GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_STR_LOADED+x}" ]; then
_POSHLI_STR_LOADED=1

# Case mapping backend: gawk when available, else awk. gawk is an optional
# dependency that enables Unicode simple case mapping in a UTF-8 locale.
# Otherwise (mawk, BusyBox awk, ...) awk typically leaves non-ASCII bytes
# unchanged in the C and UTF-8 locales; the result still depends on the
# active locale and on the awk implementation.
if command -v gawk >/dev/null 2>&1; then
	_POSHLI_AWK=gawk
else
	_POSHLI_AWK=awk
fi

is_empty() {
#	Returns 0 if no argument is given or the argument is empty.
#
#	Example of use:
#	is_empty "$STR" && echo "String is empty" || echo "String is not empty"
#
	[ $# -eq 0 ] || [ -z "$1" ]
}

trim() {
#	Prints the argument with leading and trailing spaces and tabs removed.
#
#	Example of use:
#	TRIMMED=$(trim "  hello  ")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	_trim_str=$1
	_trim_str=${_trim_str#"${_trim_str%%[! 	]*}"}
	_trim_str=${_trim_str%"${_trim_str##*[! 	]}"}
	printf '%s\n' "$_trim_str"
	unset _trim_str
}

lower() {
#	Prints the argument converted to lowercase.
#
#	Example of use:
#	LOWER=$(lower "HELLO")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print tolower($0) }'
}

upper() {
#	Prints the argument converted to uppercase.
#
#	Example of use:
#	UPPER=$(upper "hello")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print toupper($0) }'
}

starts_with() {
#	Returns 0 if the first argument begins with the second argument.
#
#	Example of use:
#	starts_with "https://example.com" "https" && echo "URL uses HTTPS" || echo "URL does not use HTTPS"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

ends_with() {
#	Returns 0 if the first argument ends with the second argument.
#
#	Example of use:
#	ends_with "script.sh" ".sh" && echo "Shell script" || echo "Not a shell script"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2") return 0 ;;
		*) return 1 ;;
	esac
}

contains() {
#	Returns 0 if the first argument contains the second argument.
#
#	Example of use:
#	contains "hello world" "world" && echo "Substring found" || echo "Substring not found"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

str_len() {
#	Prints the number of Unicode code points in the argument.
#
#	Example of use:
#	LEN=$(str_len "España")
#
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
	printf '%s' "$1" | od -An -v -tu1 | awk '
		{
			for (i = 1; i <= NF; i++)
				if ($i < 128 || $i >= 192)
					n++
		}
		END { print n + 0 }
	'
}

str_len_bytes() {
#	Prints the exact number of bytes in the argument.
#
#	Example of use:
#	BYTES=$(str_len_bytes "España")
#
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
	printf '%s' "$1" | wc -c | awk '{print $1}'
}

str_replace() {
#	Prints the third argument with every occurrence of the first replaced by the second.
#
#	Example of use:
#	RESULT=$(str_replace "foo" "bar" "foo baz")
#
	[ $# -ge 3 ] || return 2
	[ -n "$1" ] || { printf '%s\n' "$3"; return 0; }
	_sr_search="$1"
	_sr_replace="$2"
	_sr_str="$3"
	_sr_out=""

	while case "$_sr_str" in *"${_sr_search}"*) true ;; *) false ;; esac; do
		_sr_prefix="${_sr_str%%"${_sr_search}"*}"
		_sr_out="${_sr_out}${_sr_prefix}${_sr_replace}"
		_sr_rest="${_sr_str#"${_sr_prefix}""${_sr_search}"}"
		_sr_str="$_sr_rest"
	done
	_sr_out="${_sr_out}${_sr_str}"
	printf '%s\n' "$_sr_out"
	unset _sr_search _sr_replace _sr_str _sr_out _sr_prefix _sr_rest
}
fi

#
#    Copyright 2017 L. Gonzalo Fernández-Díez Martínez
#
#    This file is part of poshli.
#
#    poshli is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as 
#    published by the Free Software Foundation, either version 3 of the 
#    License, or (at your option) any later version.
#
#    poshli is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public 
#    License along with poshli. If not, see <http://www.gnu.org/licenses/>.
#
#__


#
#	Strings in poshli
#
#	Third party: https://www.gnu.org/software/
#

str_replace()
{
	#	Prints a given string with the result of replacing all @1 for @2 in @3.
	#
	#	Syntax:	str_replace [-r] "search" "replace" "main string"
	#
	#				-r				Enable support for regular expressions.
	#				"search":		keyword or pattern for search.
	#				"replace":		Replacement string, if -r is activated "&" will 
	#								expanded as the searched string.
	#				"main string":	The main string where to replace.
	#
	#	Example 1:	str_replace=$(str_replace "y" "ad" "my dog")
	#
	#	Example 2:	str_replace=$(str_replace -r "[g]$" "&s" "my dog")
	#
	[ $# -lt 3 ] && return 22
	rflag=
	fflag=
	while getopts rf: name
	do
		case $name in
			r)	rflag=1;;
			f)	fflag=1	# for future development.
				bval="$OPTARG";;
			?)	return 22;;
		esac
	done
	if [ ! -z "$rflag" ]; then
		#
		#	With RegEx support, -r flag activated:
		#
		shift $(($OPTIND - 1))
		printf '%s\n' "${3}" | pat="${1}" rep="${2}" awk --posix '{	gsub(ENVIRON["pat"], ENVIRON["rep"]); print
			}' || return 1 &&
		return 0
	fi
	if [ ! -z "$fflag" ]; then
		# for future development.
		shift $(($OPTIND - 1))
		return 0
	fi
	#
	#	Without RegEx support:
	#
	printf '%s' "${3}" |
		sed --posix "s/$(str_scape_pattern ${1})/$(str_scape_replacement ${2})/g" || 
		return 1 &&
	return 0
}

str_scape_pattern()
{
	#	prints a string by escaping characters corresponding to regex patterns.
	#
	#	Example:	replacement=$(str_scape_pattern "[a-z]")
	#
	[ $# -lt 1 ] && return 22
	printf '%s' "${1}" | sed --posix 's:[][\/.^$*]:\\&:g' || return 1 &&
	return 0
}

str_scape_replacement()
{
	#	prints a string by escaping characters corresponding to regex replacements.
	#
	#	Example:	replacement=$(str_scape_replacement "hi&bye")
	#
	[ $# -lt 1 ] && return 22
	printf '%s' "${1}" | sed --posix 's:[\/&]:\\&:g;$!s/$/\\/' || return 1 &&
	return 0
}

str_lower()
{
	#	Prints a lower case conversion of input parameter.
	#
	#	Example of use:	lowercase=$(str_lower "${str}")
	#
	[ $# -lt 1 ] && return 22
	printf '%s' "${*}" | awk --posix '{printf tolower($0)}' || return 1 &&
	return 0
}

str_upper()
{
	#	Prints an upper case conversion of input parameter.
	#
	#	Example of use:	uppercase=$(str_upper "${str}")
	#
	[ $# -lt 1 ] && return 22
	printf '%s' "${*}" | awk --posix '{printf toupper($0)}' || return 1 &&
	return 0
}

str_len()
{
	#	Prints the length of the string.
	#
	#	Example:	string=$(str_len "España")
	#
	#	Result:		str_len is 6
	#
	[ $# -lt 1 ] && return 22

	#	This is the main string length counter:
	str_len_temp=$(printf %s "${*}" | wc -m) || return 1 &&

	#	This is for what the string to be a numeric digit.
	str_len_temp=$(expr ${str_len_temp}) || return 1 &&

	printf '%u' ${str_len_temp} || return 1 &&
	unset -v str_len_temp
	return 0
}

str_len_bytes()
{
	#	Prints the length in bytes of the string.
	#
	#	Example:	string=$(str_len_bytes "España")
	#
	#	Result:		str_len is 7
	#
	[ $# -lt 1 ] && return 22

	#	This is the main byte counter:
	str_len_bytes_temp=$(printf %s "${*}") || return 1 &&
	
	#	This is for what the string to be a numeric digit.
	str_len_bytes_temp=$(expr length "${str_len_bytes_temp}") || return 1 &&

	printf '%u' ${str_len_bytes_temp} || return 1 &&
	unset -v str_len_bytes_temp
	return 0
}


#	poshli's developers comments:
#
#	> Functions must follow the order they have.
#
#	> Some functions uses awk to cover utf8 characters with less consumption, but other 
#	  ways will be consider.
#
#	> expr is used some times for the returned string to be a numeric digit.
#	  https://www.gnu.org/software/libc/manual/html_node/Table-of-Output-Conversions.html
#	  I am not sure if it's necessary.
#
#	> wc is used because characters are counted instead of bytes even in utf8.
#
#	> str_replace="${3//$1/$2}" That's not POSIX compliant.
#
#	> str_replace uses sed for less resource consumption, and awk for better flexibility 
#	  with patterns in regular expressions.

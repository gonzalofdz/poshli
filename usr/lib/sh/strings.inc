#
#    Copyright 2017 L. Gonzalo Fernández-Díez Martínez
#
#    This file is part of lispo.
#
#    lispo is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as 
#    published by the Free Software Foundation, either version 3 of the 
#    License, or (at your option) any later version.
#
#    lispo is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public 
#    License along with lispo. If not, see <http://www.gnu.org/licenses/>.
#
#__


#
#	Strings in lispo
#
#	Third party: https://www.gnu.org/software/
#

str_replace()
{
	#	Prints a given string with the result of replacing all @1 for @2 in @3.
	#	This command is as [tr] but strings oriented
	#	Regular expressions or POSIX char class are NOT allowed.
	#	It's case sensitive. 
	#
	#	Syntax:		str_replace "search" "replace" "main string"
	#
	#					"search":		Regular expressions aren't accepted.
	#					"replace":		The replacement string.
	#					"main string":	The main string where to replace.
	#
	#	Example:	str_replace=$(str_replace "y" "ad" "my dog")
	#
	str_replace_pattern=$(str_scape_pattern ${1})
	str_replace_replace=$(str_scape_replacement ${2} )
	printf '%s' "${3}" | sed --posix "s/${str_replace_pattern}/${str_replace_replace}/g" || return 1 &&
	return 0
}

str_scape_pattern()
{
	#	prints a string by escaping characters corresponding to regular expression patterns.
	#
	printf '%s' "${1}" | sed --posix 's:[][\/.^$*]:\\&:g' || return 1 &&
	return 0
}

str_scape_replacement()
{
	#	prints a string by escaping characters corresponding to regular expression replacements.
	#
	printf '%s' "${1}" | sed --posix 's:[\/&]:\\&:g;$!s/$/\\/' || return 1 &&
	return 0
}

str_lower()
{
	#	Prints a lower case conversion of input parameter.
	#
	#	Example of use:	lowercase=$(str_lower "${str}")
	# 
	printf '%s' "${*}" | awk '{printf tolower($0)}' || return 1 &&
	return 0
}

str_upper()
{
	#	Prints an upper case conversion of input parameter.
	#
	#	Example of use:	uppercase=$(str_upper "${str}")
	# 
	printf '%s' "${*}" | awk '{printf toupper($0)}' || return 1 &&
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

	#	This is the main string length counter:
	str_len_temp=$(printf %s "${*}" | wc -m) || return 1 &&

	#	This is for what the string to be a numeric digit.
	str_len_temp=$(expr ${str_len_temp}) || return 1 &&

	printf '%u' ${str_len_temp} || return 1 &&
	unset -v str_len_temp || return 1 &&
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

	#	This is the main byte counter:
	str_len_bytes_temp=$(printf %s "${*}") || return 1 &&
	
	#	This is for what the string to be a numeric digit.
	str_len_bytes_temp=$(expr length "${str_len_bytes_temp}") || return 1 &&

	printf '%u' ${str_len_bytes_temp} || return 1 &&
	unset -v str_len_bytes_temp || return 1 &&
	return 0
}


#	lispo developers comments:
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

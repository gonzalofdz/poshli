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


#	Strings in lispo
#
#	Third party: https://www.gnu.org/software/

str_replace()
{
	#	Prints $str_replace whit the result of replacing @1 for @2 in @3.
	#	Regular expressions are not allowed. It's case sensitive.
	#
	#	Syntax:
	#				str_replace "chage this" "by this" "main string"
	#
	#	Example:
	#				str_replace=$(str_replace "y" "ad" "my dog")
	#
	str_replace=$(printf '%s' "$3" | tr "$1" "$2") || return 1 &&
	printf '%s' "$str_replace" || return 1 &&
	return 0
}

str_lower()
{
	#	Prints a lower case conversion of input parameter.
	#
	#	Example of use:	lowercase=$(str_lower "${str}")
	# 
	str_lower=$(printf '%s' "${*}" | awk '{printf tolower($0)}') || return 1 &&
	printf '%s' "$str_lower" || return 1 &&
	return 0
}

str_upper()
{
	#	Prints an upper case conversion of input parameter.
	#
	#	Example of use:	uppercase=$(str_upper "${str}")
	# 
	str_upper=$(printf '%s' "${*}" | awk '{printf toupper($0)}') || return 1 &&
	printf '%s' "$str_upper" || return 1 &&
	return 0
}

str_len()
{
	#	Prints the length of the string.
	#
	#	Example:	string=$(str_len "España")
	#
	#	Result:		6
	#
	str_len=$(printf %s "${*}" | wc -m) || return 1 &&
	str_len=$(expr ${str_len}) || return 1 &&
	printf '%u' ${str_len} || return 1 &&
	return 0
}

str_len_bytes()
{
	#	Prints the length in bytes of the string.
	#
	#	Example:	string=$(str_len_bytes "España")
	#
	#	Result:		7
	#
	str_len_bytes=$(printf %s "${*}") || return 1 &&
	str_len_bytes=$(expr length "${str_len_bytes}") || return 1 &&
	printf '%u' ${str_len_bytes} || return 1 &&
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
#
#	> wc is used because characters are counted instead of bytes even in utf8.
#
#	> str_replace="${3//$1/$2}" That's not POSIX compliant.
#

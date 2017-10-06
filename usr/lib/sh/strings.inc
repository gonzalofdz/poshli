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
#	Functions must follow the order they have.
#

str_change()
{
	#	Change @1 for @2 in @3
	#		( Quotation marks needed. )
	#
	#	Sintaxis:
	#		str_change "chage this" "for this" "main string"
	#
	#	Example:
	#		str_change "y" "ad" "my dog"
	#
	string="${3-}"
	changeThis="${1}"
	forThisOne="${3}"
	str_change=`printf '%s' "${string}" | sed s/"${changeThis}"/"${forThisOne}"/g`
	return 0
}

str_lower()
{
	#	Creates a variable called $str_lower with lower case conversion 
	#	to input parameter.
	#
	#	Example:	str_lower "$str"; printf '%s' "$str_lower"
	# 
	str_lower=`printf '%s' "${*}" | awk '{printf tolower($0)}'`
	return 0
}

str_upper()
{
	#	Upper case.
	#
	#	Example:	str_upper "lowercase string"
	#
	str_upper=`printf '%s' "${*}" | awk '{printf toupper($0)}'`
	return 0
}

str_len()
{
	#	Creates a variable called $str_len with the length of the string
	#
	#	Example:	str_len "this string"
	#
	str_len=`printf %s "${*}" | wc -m` &&
	str_len=`expr ${str_len}` &&
	str_len=`printf %u ${str_len}`
	return 0
}

#
#	lispo developers comments:
#
#	> Some functions uses awk to cover utf8 characters with less consumption.
#	> expr is used some times for the returned string to be a numeric digit.
#	  https://www.gnu.org/software/libc/manual/html_node/Table-of-Output-Conversions.html
#	> wc is used because characters are counted instead of bytes even in utf8.
#


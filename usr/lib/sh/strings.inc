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
#	Some functions uses awk to cover utf8 characters with less consumption.

str_change() {
	#
	#	Change @1 for @2 in @3
	#
	printf '%s' "$3-" | tr "$1" "$2"
}

str_lower() {
	#
	#	Print a string in lower case.
	#
	#	Example:	str_lower "UPPERCASE STRING"
	#
	printf '%s' "$*" | awk '{printf tolower($0)}'
}

str_upper() {
	#
	#	Print a string in upper case.
	#
	#	Example:	str_upper "lowercase string"
	#
	printf '%s' "$*" | awk '{printf toupper($0)}'
}

str_len() {
	#
	#	Print the length of the string
	#
	#	wc is used because characters are counted instead
	#	of bytes even in utf8.
	#
	#	Example:	str_len "this string"
	#
	printf "%s" "$*" | wc -m
}


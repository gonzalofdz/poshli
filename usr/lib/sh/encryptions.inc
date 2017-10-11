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
#	Encryptions in lispo
#
#	Third party: https://www.gnu.org/software/
#

base64_enc()
{
	#	Prints the input string base64 encoded.
	#
	#	Example:	encoded=$(base64_enc "String")
	#
	printf '%s' "${*}" | base64 || return 1 &&
	return 0
}

base64_dec()
{
	#	Prints the input string base64 encoded.
	#
	#	Example:	decoded=$(base64_enc "$(encoded)")
	#
	printf '%s' "${*}" | base64 -d || return 1 &&
	return 0
}

#	lispo developers comments:
#
#	> Functions must follow the order they have.
#
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
#	File system in lispo
#
#	Third party: https://www.gnu.org/software/
#


is_plain_text()
{
	#	Is a plain text file?
	#
	#	Example of use:
	#	( is_plain_text "${HOME}/.profile" ) && echo "Plain text file" || echo "That's not true"
	#
	[ -r "${1}" ] || return 2

	plain_txt=$( file "${1}" | grep 'text' )

	[ -n "${plain_txt}" ] && true || false
}




#	lispo developers comments:
#
#	> 
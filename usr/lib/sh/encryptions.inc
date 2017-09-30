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
#	Functions must follow the order they have.
#

base64_enc()
{
	#	Print a string base64 encrypted.
	#
	#	Example:	base64_code "String"
	# 
	printf '%s' "$*" | base64
}


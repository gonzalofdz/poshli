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
#	All includes from lispo (A ring to govern them all).
#
#	Settings:
#
#	lispo_path
#
lispo_path='/usr/lib/sh'

	# Strings
. ${lispo_path}/strings.inc

	# Numbers
. ${lispo_path}/numbers.inc

	# File system
. ${lispo_path}/filesystem.inc

	# Encryptions
. ${lispo_path}/encryptions.inc


#	lispo developers comments:
#
#	> Legitimacy of the inclusion's dot can be verified in:
#	  http://bit.ly/2yWpXaR
#

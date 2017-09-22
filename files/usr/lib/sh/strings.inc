#
#    Copyright 2017 L. Gonzalo Fernández-Díez Martínez
#
#    This file is part of lispo.
#
#    lispo is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    lispo is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with lispo.  If not, see <http://www.gnu.org/licenses/>.

#
#	Strings in lispo
#
#	Functions must follow the order they have
#

is_pattern_match() {
	#
	#	Is the sentence ($1) into the pattern ($2)? [ no: 1  yes: 0 ]
	#
	#	Example: if ( is_pattern_match "$number" "0-9" ); then ...
	#
	( printf '%s' "$1" | grep -xEq "$2" ) && return 0 || return 1
}

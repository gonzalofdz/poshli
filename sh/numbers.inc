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
#___


#
#	Functions must follow the order they have
#
#	bool		number 0 or 1 only!	( ex. 1		)
#	int			number integer		( ex. -432	)
#	natural		number natural		( ex. 4324	)
#	float		number float		( ex. 432.4	)
#	bin			number binary		( ex. 1001101	)
#	hex			number hexadecimal	( ex. 23F340EA	)

is_pat() 
{
	#	Is the sentence ($1) into the pattern ($2)? [ no: false  yes: true ]
	#
	#	if ( is_pattern_match "$number" "0-9" ); then ...
	#
	( printf '%s' "$1" | grep -xEq "$2" ) && true || false
}

is_int()
{
	#	Is the parameter an integer??? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_int "-34" ) && echo "integer" || echo "not int"
	#
	( is_pat "$1" "^[+-]?[0-9]+$" ) && true || false
}

is_natural()
{
	#	Is the parameter a natural number? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_natural "$number" ) && echo si || echo no
	#
	( is_pat "$1" "[[:digit:]]*" ) && true || false
}

is_float()
{
	#	Is the parameter a float number? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_floatl "$number" ) && echo si || echo no
	#
	( is_pat "$1" "[.[:digit:]]*" ) && true || false
}

is_bin()
{
	#	Is the parameter a binary number? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_bin "$number" ) && echo si || echo no
	#
	( is_pat "$1" "[01]*" ) && true || false
}

is_bool()
{
	#	Is the parameter a boolean value??? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_bool "$number" ) && echo si || echo no
	#
	( is_pat "$1" "([01]?)" ) && true || false
}

is_hex()
{
	#	Is the parameter an hexadecimal number? [ no: 1  yes: 0 ]
	#
	#	Example of use:
	#	( is_hex "$number" ) && echo si || echo no
	#
	( is_pat "$1" "[[:xdigit:]]*" ) && true || false
}

randomize()
{
	#	Prints a number between 0 and the given parameter ($1) less one
	#
	#	Example: RANDNUM=`randomize 5`
	#
	( is_natural "$1" ) && awk "BEGIN { srand(); printf(\"%u\",rand()*$1) }" || return 1
}



#	poshli developers comments:
#
#	> Functions must follow the order they have.
#

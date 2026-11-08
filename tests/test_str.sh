#!/bin/sh
#
# POSHLI - Unit tests for str.sh
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/str.sh"
fi

printf '\n--- Running str.sh tests ---\n'

# Argument count validation
trim; assert_status 2 $? "trim requires argument (status 2)"
lower; assert_status 2 $? "lower requires argument (status 2)"
upper; assert_status 2 $? "upper requires argument (status 2)"
starts_with "foo"; assert_status 2 $? "starts_with requires 2 arguments (status 2)"
ends_with "foo"; assert_status 2 $? "ends_with requires 2 arguments (status 2)"
contains "foo"; assert_status 2 $? "contains requires 2 arguments (status 2)"
str_len; assert_status 2 $? "str_len requires argument (status 2)"
str_replace "a" "b"; assert_status 2 $? "str_replace requires 3 arguments (status 2)"

# is_empty
is_empty ""; assert_true $? "is_empty: empty string"
is_empty; assert_true $? "is_empty: no arguments is empty"
is_empty "hello"; assert_false $? "is_empty: non-empty string"
is_empty " "; assert_false $? "is_empty: space is not empty"
is_empty "0"; assert_false $? "is_empty: 0 is not empty"

# trim
res=$(trim "hola"); assert_eq "hola" "$res" "trim: no spaces"
res=$(trim " hola "); assert_eq "hola" "$res" "trim: single spaces"
res=$(trim "    hola    "); assert_eq "hola" "$res" "trim: multiple spaces"
res=$(trim "	hola	"); assert_eq "hola" "$res" "trim: tabs"
res=$(trim " 	  hola 	 "); assert_eq "hola" "$res" "trim: mixed spaces and tabs"
res=$(trim "  hola   mundo  "); assert_eq "hola   mundo" "$res" "trim: preserves interior spaces"
res=$(trim "     "); assert_eq "" "$res" "trim: only spaces"
res=$(trim "		"); assert_eq "" "$res" "trim: only tabs"
res=$(trim ""); assert_eq "" "$res" "trim: empty string"
res=$(trim "  *.*  "); assert_eq "*.*" "$res" "trim: wildcards"
res=$(trim "  -n  "); assert_eq "-n" "$res" "trim: leading hyphen"

# lower
res=$(lower "HELLO"); assert_eq "hello" "$res" "lower: all uppercase"
res=$(lower "Hello World"); assert_eq "hello world" "$res" "lower: mixed case"
res=$(lower "123 ABC !?"); assert_eq "123 abc !?" "$res" "lower: numbers and symbols"
res=$(lower ""); assert_eq "" "$res" "lower: empty string"

# upper
res=$(upper "hello"); assert_eq "HELLO" "$res" "upper: all lowercase"
res=$(upper "Hello World"); assert_eq "HELLO WORLD" "$res" "upper: mixed case"
res=$(upper "123 abc !?"); assert_eq "123 ABC !?" "$res" "upper: numbers and symbols"
res=$(upper ""); assert_eq "" "$res" "upper: empty string"

# starts_with
starts_with "http://example.com" "http://"; assert_true $? "starts_with: URL protocol"
starts_with "foobar" "foo"; assert_true $? "starts_with: prefix"
starts_with "foobar" "foobar"; assert_true $? "starts_with: exact match"
starts_with "foobar" ""; assert_true $? "starts_with: empty prefix"
starts_with "foobar" "bar"; assert_false $? "starts_with rejects: wrong prefix"
starts_with "" "foo"; assert_false $? "starts_with rejects: empty target"

# ends_with
ends_with "archive.tar.gz" ".tar.gz"; assert_true $? "ends_with: compound extension"
ends_with "script.sh" ".sh"; assert_true $? "ends_with: extension"
ends_with "foobar" "foobar"; assert_true $? "ends_with: exact match"
ends_with "foobar" ""; assert_true $? "ends_with: empty suffix"
ends_with "foobar" "foo"; assert_false $? "ends_with rejects: wrong suffix"
ends_with "" "bar"; assert_false $? "ends_with rejects: empty target"

# contains
contains "the quick brown fox" "brown"; assert_true $? "contains: middle substring"
contains "the quick brown fox" "the"; assert_true $? "contains: start substring"
contains "the quick brown fox" "fox"; assert_true $? "contains: end substring"
contains "foobar" ""; assert_true $? "contains: empty substring"
contains "the quick brown fox" "cat"; assert_false $? "contains rejects: absent substring"
contains "" "foo"; assert_false $? "contains rejects: empty target"

# str_len
res=$(str_len "hello"); assert_eq "5" "$res" "str_len: 5 chars"
res=$(str_len ""); assert_eq "0" "$res" "str_len: 0 chars"
res=$(str_len "   "); assert_eq "3" "$res" "str_len: 3 spaces"
res=$(str_len "España"); assert_true $? "str_len: handles international chars without crash"

# str_replace
res=$(str_replace "dog" "cat" "my dog is a dog"); assert_eq "my cat is a cat" "$res" "str_replace: simple words"
res=$(str_replace "and" "&" "bread and butter"); assert_eq "bread & butter" "$res" "str_replace: replace with ampersand"
res=$(str_replace "&" "and" "bread & butter"); assert_eq "bread and butter" "$res" "str_replace: replace ampersand"
res=$(str_replace "/" "\\" "/usr/bin"); assert_eq "\\usr\\bin" "$res" "str_replace: slashes and backslashes"
res=$(str_replace "." "_" "a.b.c"); assert_eq "a_b_c" "$res" "str_replace: dots"
res=$(str_replace "[a]" "[b]" "letters [a] and [a]"); assert_eq "letters [b] and [b]" "$res" "str_replace: brackets"
res=$(str_replace "*" "#" "star * and *"); assert_eq "star # and #" "$res" "str_replace: asterisks"
res=$(str_replace "?" "!" "what? really?"); assert_eq "what! really!" "$res" "str_replace: question marks"
res=$(str_replace "foo" "bar" "hello world"); assert_eq "hello world" "$res" "str_replace: pattern not found"
res=$(str_replace "" "x" "hello"); assert_eq "hello" "$res" "str_replace: empty search"

test_summary

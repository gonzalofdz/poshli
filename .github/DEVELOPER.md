###### © 2017 L. Gonzalo Fernández-Díez Martínez <humanogonzalo@gmail.com>

# Developer documentation

* <a href="#welcome">Welcome!</a>
* <a href="#shell">The Shell</a>
* <a href="#coding-rules">Coding rules</a>
 * <a href="#posixres">POSIX resources</a>
 * <a href="#afunction">What a function must do</a>
 * <a href="#varsandfunc">Variables and Functions</a>
 * <a href="#formating">Formating the code</a>
* <a href="#documentation">Documentation</a>
<a name="welcome"></a>

# Welcome! :zap:

If you are reading this document then you are interested in contributing to the poshli 
project, many thanks for that! :clap:
All contributions are welcome: ideas, documentation, code, patches, bug reports, 
feature requests, etc.  And you don't need to be a programmer to speak up.

<a name="shell"></a>

# What shell can I use to testing the code?

**/bin/sh**

Almost always [DASH](http://gondor.apana.org.au/~herbert/dash/) (*D*ebian *A*lmquist 
*SH*ell).

<a name="coding-rules"></a>

# Coding Rules

_To ensure consistency throughout the source code, keep these rules in mind as you 
are working._
<a name="afunction"></a>

**A function only must to do**  (one of these)**:**
 - Print the result and return 0 sucess or 1 error.
 - Only returns  0 (true) or 1 (false)
<a name="posixres"></a>

**Uses all available POSIX resources**.

A list of available POSIX-compliant programs: 
http://shellhaters.org/
 
 Example of an __inappropriate__ function:
 ```sh
 base64_enc()
 {
 	chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 	var="`echo $base_64_chars | cut -c1-$x`";
 	etc...
 }
 ```
 _It's inappropriate because already exists a base64 POSIX-compliant program that 
 solves it better and faster._
 
 Example of a **proper** function:
 ```sh
base64_enc()
{
	#	Prints the input string base64 encoded.
	#
	#	Example:	encoded=$(base64_enc "String")
	#
	printf '%s' "${*}" | base64 || return 1 &&
	return 0
}
 ```
 It value lies in that the function gives to developer a POSIX-compliant way of 
 solving a task.
 
 *Why not 'echo'? it's shortener.*:thought_balloon: 
 Because the usefulness of these functions is to be able to use them to handle 
 variables, and a carriage return is not friendly with variables, "echo -n" would 
 solve the issue, but then it wouldn't be POSIX-compliant.

Please **Read 
 [SECURITY.md](https://github.com/gonzalofdz/poshli/blob/master/.github/SECURITY.md)**. 
 Security is fundamental in the code of this project, otherwise this project would 
 not make sense.
 <a name="varsandfunc"></a>

#### Variables and function:

 * Descriptive names but short as possible, do use well-known acronyms when necessary.
   for example, use UI for User Interface and Html for Hyper-Text Markup Language.

  * For abbreviations, at least 3 letters each word, except if the word itself has less 
   letters. For example, bin as binary is proper because it's intuitive, but b as byte is 
   inappropriate because it would be confused with bit, byte, bypass, etc..
   
 * Every variable must be unseted at the end of the function.
 <a name="formating"></a>

#### Formating the code:

There are no better nor worse ways to format, the important thing is that a whole team 
use the same rules, and this team use the following:

* Tab to indent, if you prefer you can coding with spaces and 
  [convert](https://www.browserling.com/tools/spaces-to-tabs).

* Each tab as 4 spaces. If your code editor doesn't have the tabs set up for 4-space 
  equivalence, then note that comments will be skewed for editors like vi, if possible, 
  set your editor to tabs equivalent to 4 spaces. If you want a plugin for your IDE that 
  does the configuration for you, you have it available in:
  [EditorConfig](http://editorconfig.org/#download)

* Type the words of Functions name's in lowercase, separated by underscore and curly 
  bracket in the next line to main name.

* Type the words of Variable name's in lowercase separated by underscore or camelCase at 
  your preferred way.

* Names of Constants in uppercase separated by underscore.

* Wrap all code at 100 characters.

* The new line characters with LF (Unix), you can to use a
  [converter](http://newline.nadav.org/) if you need it.

 <a name="documentation"></a>
 
#### External documentation about coding:

 > :link: [Intro to POSIX](http://people.fas.harvard.edu/~lib113/reference/unix/portable_scripting.html)
 >
 > :link: [DashAsBinSh](https://wiki.ubuntu.com/DashAsBinSh)
 >
 > :link: [About IEEE Std 1003.1 Issue 6](http://bit.ly/2jkXDdD)
 >
 > :link: [About IEEE Std 1003.1 Issue 7](http://pubs.opengroup.org/onlinepubs/9699919799/)
 >
 > :link: [The Shell Hater's Handbook](http://shellhaters.org/)
 >
 > :link: [Richard Stallman's personal site](https://stallman.org/articles/posix.html)


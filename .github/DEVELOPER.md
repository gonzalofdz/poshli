###### © 2017 L. Gonzalo Fernández-Díez Martínez <humanogonzalo@gmail.com>

# Developer documentation

* <a href="#welcome">Welcome!</a>
* <a href="#coding-rules">Coding rules</a>
* <a href="#documentation">Documentation</a>

<a name="welcome"></a>

# Welcome!

If you are reading this document then you are interested in contributing to the lispo 
project, many thanks for that!
All contributions are welcome: ideas, documentation, code, patches, bug reports, 
feature requests, etc.  And you do notneed to be a programmer to speak up.

<a name="coding-rules"></a>

# Coding Rules

**Uses all available POSIX resources**. A list of available POSIX-compliant programs: 
http://shellhaters.org/
 
 Example of an __inappropriate__ function:
 ```sh
 base64_code()
 {
 	base_64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 	var="`echo $base_64_chars | cut -c1-$x`";
 	etc...
 }
 ```
 It's inappropriate because already exists a base64 POSIX-compliant program that solves it better 
 and faster.
 
 Example of a __proper__ function:
 ```sh
 base64_code()
  {
    #	Print a string encoded in base64
    #
    #	Example:	base64_code "String"
    # 
 	printf '%s' "String" | base64
 }
 ```
 It value lies in that the function gives to developer a POSIX-compliant way of solving 
 a task, although it could also be done as follows:
 printf '%s' "String" | base64
 but is shorter base64_code "String", and after all will be the decision of the final 
 developer to use the chosen way for each occasion.
 
 Why not 'echo'? it's shortener.
 Because the usefulness of these functions is to be able to use them to handle variables, 
 and a carriage return is not friendly with variables, "echo -n" would solve the issue, but 
 then it wouldn't be POSIX-compliant.

**Read [SECURITY.md](https://github.com/gonzalofdz/lispo/blob/master/.github/SECURITY.md)**. 
 Security is fundamental in the code of this project, otherwise this project would not make 
 sense.
 
 <a name="documentation"></a>
 
#### External documentation about coding:

 >* [DashAsBinSh](https://wiki.ubuntu.com/DashAsBinSh)
 >* [About IEEE Std 1003.1 Issue 6](http://pubs.opengroup.org/onlinepubs/009695399/utilities/contents.html)
 >* [About IEEE Std 1003.1 Issue 7](http://pubs.opengroup.org/onlinepubs/9699919799/)
 >* [The Shell Hater's Handbook](http://shellhaters.org/)

Tests for syntax highlighting plugins
=====================================

Summary: Files in the "input" directory are edited by Vim with syntax
highlighting enabled.  Screendumps are generated and compared with the
expected screendumps in the "dumps" directory.  This will uncover any
character attributes that differ.

Without any further setup a screendump is made at the top of the file (using
_00.dump) and another one at the end of the file (using _99.dump).  The dumps
are normally 20 screen lines tall.

When the screendumps are OK an empty "done/{name}" file is created.  This
avoids running the test again until "make clean" is used.  Thus you can run
"make test", see one test fail, try to fix the problem, then run "make test"
again to only repeat the failing test.

When a screendump differs it is stored in the "failed" directory.  This allows
for comparing it with the expected screendump, using a command like:

	let fname = '{name}_99.dump'
	call term_dumpdiff('failed/' .. fname, 'dumps/' .. fname)


Creating a syntax plugin test
-----------------------------

Create a source file in the language you want to test in the "input"
directory.  Use the filetype name as the base and a file name extension
matching the filetype.  Let's use Java as an example.  The file would then be
"input/java.java".

Make sure to include some interesting constructs with plenty of complicated
highlighting.  Optionally, pre-configure the testing environment by including
setup commands at the top of the input file.  The format for these lines is:

	VIM_TEST_SETUP {command}

where {command} is any valid Ex command, which extends to the end of the line.
The first 20 lines of the input file are ALWAYS scanned for setup commands and
these will be executed before the syntax highlighting is enabled.  Typically,
these lines would be included as comments so as not to introduce any syntax
errors in the input file but this is not required.

Continuing the Java example:

	// VIM_TEST_SETUP let g:java_space_errors = 1
	// VIM_TEST_SETUP let g:java_minlines = 5
	class Test { }

As an alternative, setup commands can be included in an external Vim script
file in the "input/setup" directory.  This script file must have the same base
name as the input file.

So, the equivalent example configuration using this method would be to create
an "input/setup/java.vim" script file with the following lines:

	let g:java_space_errors = 1
	let g:java_minlines = 5

Both inline setup commands and setup scripts may be used at the same time, the
script file will be sourced before any VIM_TEST_SETUP commands are executed.

Every line of a source file must not be longer than 1425 (19 x 75) characters.

If there is no further setup required, you can now run the tests:

	make test

The first time this will fail with an error for a missing screendump.  The
newly created screendumps will be "failed/java_00.dump",
"failed/java_01.dump", etc.  You can inspect each with:

	call term_dumpload('failed/java_00.dump')
	call term_dumpload('failed/java_01.dump')
	...
	call term_dumpload('failed/java_99.dump')

If they look OK, move them to the "dumps" directory:

	:!mv failed/java_00.dump dumps
	:!mv failed/java_01.dump dumps
	...
	:!mv failed/java_99.dump dumps

If you now run the test again, it will succeed.


Adjusting a syntax plugin test
------------------------------

If you make changes to the syntax plugin, you should add code to the input
file to see the effect of these changes.  So that the effect of the changes
are covered by the test.  You can follow these steps:

1. Edit the syntax plugin somewhere in your personal setup.  Use a file
   somewhere to try out the changes.
2. Go to the directory where you have the Vim code checked out and replace the
   syntax plugin.  Run the tests: "make test".  Usually the tests will still
   pass, but if you fixed syntax highlighting that was already visible in the
   input file, carefully check that the changes in the screendump are
   intentional:

	let fname = '{name}_99.dump'
	call term_dumpdiff('failed/' .. fname, 'dumps/' .. fname)

   Fix the syntax plugin until the result is good.
2. Edit the input file for your language to add the items you have improved.
   (TODO: how to add another screendump?).
   Run the tests and you should get failures.  Like with the previous step,
   carefully check that the new screendumps in the "failed" directory are
   good.  Update the syntax plugin and the input file until the highlighting
   is good and you can see the effect of the syntax plugin improvements.  Then
   move the screendumps from the "failed" to the "dumps" directory.  Now "make
   test" should succeed.
3. Prepare a pull request with the modified files:
	- syntax plugin:    syntax/{name}.vim
	- Vim setup file:   syntax/testdir/input/setup/{name}.vim (if any)
	- test input file:  syntax/testdir/input/{name}.{ext}
	- test dump files:  syntax/testdir/dumps/{name}_99.dump

As an extra check you can temporarily put back the old syntax plugin and
verify that the tests fail.  Then you know your changes are covered by the
test.




TODO: run test for one specific filetype
TODO: test syncing by jumping around

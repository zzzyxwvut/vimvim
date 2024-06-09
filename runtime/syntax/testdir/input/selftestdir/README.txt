The test files with made-up syntax in this directory serve for additional
linewise checks to carry out whenever the algorithm managing dump file
generation (../../runtest.vim) requires further modification.

Please test any changes as follows:
	cd runtime/syntax/
	VIM_SYNTAX_SELF_TESTING=1 make clean test


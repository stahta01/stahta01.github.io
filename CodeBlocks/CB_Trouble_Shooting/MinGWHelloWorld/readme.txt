If having an C++ building issue,
   Try batch files build-main_cpp-simple1.bat and build-main_cpp-simple2.bat

If having an C building issue,
   Try batch files build-main_c-simple1.bat and build-main_c-simple2.bat

If both simple1 and simple2 batch file works; 
you likely have a good MinGW GCC installation.

If batch file simple1 fails and simple2 works;
you likely have something in the Windows system 
environmental variable PATH that causes a problem.
Cygwin, MSys, and other MinGW GCC installations are common issues.

If both fails you need to check your system for environmental variables that could cause problems.
Ones suspected or known to have caused problems are:
	GCC_EXEC_PREFIX
	GCC_ROOT

Warning it is suspected that certain root folders can cause MinGW installation to fail.
c:\MinGW
C:\MinGW32
and other like that.

If none of the above is found it is likely you have a bad MinGW installation.


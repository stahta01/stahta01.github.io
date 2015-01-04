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

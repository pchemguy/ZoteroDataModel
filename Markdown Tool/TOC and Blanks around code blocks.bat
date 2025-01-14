@echo off


rem Adds missing blank lines around fenced code blocks (``` or ~~~).


:: ================================ BEGIN MAIN ================================
:MAIN

SetLocal EnableExtensions EnableDelayedExpansion

set STDOUTLOG=stdout.log
set STDERRLOG=stderr.log
del "%STDOUTLOG%" 2>nul
del "%STDERRLOG%" 2>nul
set ErrorStatus=0
set ERR_MSG=


set SRC=%~1
if "%SRC%"=="" (
    set ERR_MSG=The source file is not provided on the command line.
    goto :ABORT_ERR_MSG
)

if not exist "%SRC%" (
    set ERR_MSG=The source file is not found: "%SRC%"
    goto :ABORT_ERR_MSG
)

if /I  not "%~x1"==".md" (
    set ERR_MSG=Expected Markdown file ".md". Supplied file type "%~x1".
    goto :ABORT_ERR_MSG
)


set DST=%~dpn1_new.md
if exist "%DST%" (del /F /Q "%DST%")
set BUF=%~dpn1.tmp
copy /Y "%SRC%" "%BUF%"


rem -e "s/^<^!-- TOC --^>//g"
rem   Strips <^!-- TOC --^> tags added by https://derlin.github.io/bitdowntoc/
rem -e "s/^[ \t]*#/#/g"
rem   Strips leading spaces before the heading mark.
rem -e "s/^[ \t]*<^!--/<^!--/g"
rem   Strips leading spaces before the html comment tag.
rem -e "s/^!/{@@@}/g"
rem -e "s/&/{@}/g" ^
rem   Masks exclamation marks and ampersands for further processing
rem -e "s/~~~/```/g"
rem   Sticks to one fencing style (not strictly necessary, 
rem   but simplifies the processing code.
rem -e "s/^^$/  /g"
rem   Adds two spaces to every empty line for correct 
rem   processing in the "for /f" loop.

sed  -e "s/^<^!-- TOC --^>//g" ^
     -e "s/^[ \t]*#/#/g" ^
     -e "s/^[ \t]*<^!--/<^!--/g" ^
     -e "s/^!/{~}/g" ^
     -e "s/&/{@}/g" ^
     -e "s/~~~/```/g" ^
     -e "s/^^$/  /g" ^
     -i "%BUF%"

rem Loops through the lines in the buffer file and adds missing 
rem blank lines around fenced code blocks (``` or ~~~).

set "DOUBLE_SPACE=  "
set PREV_LINE=
set OPENED_CODE_BLOCK=
set CUR_LINE_FENCED=
set PREV_LINE_FENCED=
set SKIP_NL=

for /f "usebackq tokens=* delims=" %%G in ("%BUF%") do (
  set CUR_LINE=%%G
  
  rem Test for presence of either style code block

  set CUR_LINE_FENCED=1
  if not "!CUR_LINE:~0,3!"=="```" set CUR_LINE_FENCED=
  if "!CUR_LINE:~4,5!"=="`" set CUR_LINE_FENCED=

  rem A new line is injected if an empty line is missing 
  rem   a) before the code block, that is ALL is true
  rem       * CUR_LINE_FENCED=1,
  rem       * PREV_LINE is not empty, and
  rem       * OPENED_CODE_BLOCK=
  rem      N.B.: Empty line is injected BEFORE the fenced line when the fenced
  rem            line is processed / current.
  
  set SKIP_NL=
  if "!CUR_LINE_FENCED!"==""    set SKIP_NL=1
  if "!PREV_LINE: =!"==""       set SKIP_NL=1
  if "!OPENED_CODE_BLOCK!"=="1" set SKIP_NL=1
  if "!SKIP_NL!"=="" echo:%DOUBLE_SPACE%

  rem   b) after the code block, that is ALL is true
  rem       * PREV_LINE_FENCED=,
  rem       * CUR_LINE is not empty, and
  rem       * OPENED_CODE_BLOCK=1
  rem      N.B.: Empty line is injected AFTER the fenced line when the line after
  rem            the fenced line is processed / current. At this point, the fenced
  rem            line has been emmited in the previous cycle and the code block has
  rem            been set "closed". So the blank line needs to be injected again
  rem            BEFORE the current line and test that the code block is CLOSED.
  
  set SKIP_NL=
  if "!PREV_LINE_FENCED!"==""   set SKIP_NL=1
  if "!CUR_LINE: =!"==""        set SKIP_NL=1
  if "!OPENED_CODE_BLOCK!"=="1" set SKIP_NL=1
  if "!SKIP_NL!"=="" echo:%DOUBLE_SPACE%

  rem Tests for space-only lines and handles accordingly

  if not "!CUR_LINE: =!"=="" (
      echo !CUR_LINE!
  ) else (
      echo:%DOUBLE_SPACE%
  )

  rem Updates the state for the next cycle
  
  if "!CUR_LINE_FENCED!"=="1" (
      set PREV_LINE_FENCED=1

      if "!OPENED_CODE_BLOCK!"=="" (
          set OPENED_CODE_BLOCK=1
      ) else (
          set OPENED_CODE_BLOCK=
      )
  ) else (
      set PREV_LINE_FENCED=
  )
  set PREV_LINE=!CUR_LINE!
  
) 1>>"%DST%"

rem COOL=========================================================================
rem Prepares new TOC
rem
rem Extracts section title/heading lines and splits them into hash preix and
rem title. Drops old anchor tags preceeding the title lines and replaces with
rem anchor tags generated from title lines including attributes:
rem   - title
rem       section title
rem   - class
rem       section hash prefix with additional "TOC " prefix
rem   - id
rem       section title -> lower-case, " " -> "-", and "." -> "_"
rem
rem Sets %TOC% to the generated TOC
rem

copy /Y "%DST%" "%BUF%" && del /F /Q "%DST%"

set PREV_LINE=
set CUR_LINE=
set TOC=**Table of Contents**  \n\n
for /f "usebackq tokens=* delims=" %%G in ("%BUF%") do (
  set CUR_LINE=%%G
  if "!CUR_LINE:~0,3!"=="<a " (
      set PREV_LINE=!CUR_LINE!
  ) else (
    if "!CUR_LINE:~0,1!"=="#" (
        call :SPLIT_TITLE "!CUR_LINE!"
        call :ANCHOR_ID_FROM_TITLE "!TITLE!"
        call :TOC_LINE_FROM_TITLE_ID "!ANCHOR_ID!" "!TITLE!" "!CLASS!"
        set TOC=!TOC!!TOC_LINE!\n
        echo ^<a id="!ANCHOR_ID!" class="!CLASS!" title="!TITLE!"^>^</a^>
    ) else if not "!PREV_LINE!"=="" (
        rem Tests for space-only lines and handles accordingly

        if not "!PREV_LINE: =!"=="" (
            echo !PREV_LINE!
        ) else (
            echo:%DOUBLE_SPACE%
        )
    )
    set PREV_LINE=

    rem Tests for space-only lines and handles accordingly
    
    if not "!CUR_LINE: =!"=="" (
        echo !CUR_LINE!
    ) else (
        echo:%DOUBLE_SPACE%
    )
  )
) 1>>"%DST%"


rem Removes old TOC and replaces with new one

call :UPDATE_TOC "%DST%"

rem Reverts masking

sed  -e "s/{~}/^!/g" ^
     -e "s/{@}/\&/g" ^
     -i "%DST%"


EndLocal & exit /b %ErrorStatus%
:: ================================= END MAIN =================================


:: ============================================================================
:ABORT_ERR_MSG
:: Set %ERR_MSG% before "goto" here.
::
SetLocal
set ErrorStatus=1

echo.
echo =======================================================================
echo %ERR_MSG%
echo Aborting ...
echo =======================================================================
echo.

EndLocal & exit /b %ErrorStatus%


:: ============================================================================
:ANCHOR_ID_FROM_TITLE
:: Converts section title to anchor ID.
::
:: Section titles should generally be concise without punctuation. This 
:: routine converts supplied title to lower case, replacing spaces with 
:: dashes; periods, question marks, and masked ampersands with underscores. 
::
:: Call this sub with argument(s):
::   - %1 - Section title
::
:: Returns:
::   %ANCHOR_ID% - calculated value.
::
set ANCHOR_ID=%~1
for %%H in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
  set ANCHOR_ID=!ANCHOR_ID:%%H=%%H!
)
set ANCHOR_ID=%ANCHOR_ID: =-%
set ANCHOR_ID=%ANCHOR_ID:.=_%
set ANCHOR_ID=%ANCHOR_ID:?=_%
set ANCHOR_ID=%ANCHOR_ID:{@}=_%

exit /b 0


:: ============================================================================
:SPLIT_TITLE
:: Splits supplied Markdown section title line into parts
::
:: Call this sub with argument(s):
::   - %1 - Markdown section title line including the leading hash marks
::
:: Returns:
::   %CLASS% - the "hash" prefixes (with TOC prefix), used to set <a class=...>
::   %TITLE% - actual title
::
set CLASS=%~1
set TITLE=%CLASS:#=%
set TITLE=%TITLE:~1%

set CLASS=!CLASS:%TITLE%=!
set CLASS=TOC %CLASS:~0,-1%

rem Trims title
:TRIM_TITLE
if "%TITLE:~-1%"==" " (
    set TITLE=%TITLE:~0,-1%
    goto :TRIM_TITLE
)

exit /b 0


:: ============================================================================
:TOC_LINE_FROM_TITLE_ID
:: Generates title line from section title and anchor id
::
:: Call this sub with argument(s):
::   - %1 - ANCHOR_ID
::   - %2 - TITLE
::   - %3 - CLASS (title level)
::
set LINK=[%~2](#%~1)
set INDENT=%~3
set INDENT=%INDENT:TOC =%
set INDENT=%INDENT:#=  %
set TOC_LINE=%INDENT%- %LINK%

rem echo %TOC_LINE%  1>>"%DST%.toc"

exit /b 0


:: ============================================================================
:UPDATE_TOC
:: Removes old TOC between <!-- TOC start ... --> and <!-- TOC end -->
:: This routine is called after escaping !s: ! -> {~}
::
:: Call this sub with argument(s):
::   - %1 - target file full path
::

rem Replaces old TOC with "[TOC]"

set PATTERN=\n^<{~}-- TOC start[^^^^}]*}-- TOC end --^>\([\r]*\n\)
set NEW_TXT=\n^<{~}-- [TOC] --^>\1
sed  -e "s/%PATTERN%/%NEW_TXT%/" ^
     -z ^
     -i "%~1"

rem Replaces "[TOC]" with generated TOC

set QQQPATTERN=\n^<{~}-- \[TOC\] --^>\([\r]*\n\)
set NEW_TXT=^<{~}-- TOC start --^>\1\1%TOC:\n=\1%\1^<{~}-- TOC end --^>\1
sed  -e "s/%QQQPATTERN%/%NEW_TXT%/" ^
     -z ^
     -i "%~1"

rem Removes the first heading's anchor if on the first line (for Fossil)

set PATTERN=^^^<a[^^^>]*^>^<\/a^>[\r]*\n
set NEW_TXT=
sed  -e "s/%PATTERN%/%NEW_TXT%/" ^
     -z ^
     -i "%~1"

exit /b 0

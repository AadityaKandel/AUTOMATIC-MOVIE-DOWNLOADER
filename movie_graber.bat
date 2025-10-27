echo off

REM -----------------------------------------------------------------
REM This script is designed to work with the YTS.mx website.
REM All credit for the movie access and links goes to the
REM YIFY / YTS team. This script is just an unofficial interface.
REM -----------------------------------------------------------------

cls

:phase1
echo Copyright (C) YIFY / YTS
echo This script is an unofficial tool and relies entirely on their service.
echo.
echo.
set /P "movie_namee=Please Enter The Full-Name of The Movie You Want To Download (without spelling errors): "
set /P "release_year=Please Enter The Release Year of The Movie [%movie_namee%] (only year): "

SETLOCAL EnableDelayedExpansion
REM Remove double-quote characters from the raw input to avoid breaking the PowerShell command
set "movie_namee=%movie_namee:"=%"

REM Call PowerShell to sanitize:
REM  - ToLower()
REM  - Replace any non-word, non-space characters with a space (drops most punctuation)
REM  - Collapse runs of whitespace into a single space and Trim()
FOR /F "usebackq delims=" %%a IN (`
    powershell -NoProfile -Command "$s = \"%movie_namee%\"; $s = $s.ToLower(); $s = [regex]::Replace($s,'[^\w\s]',' '); $s = [regex]::Replace($s,'\s+',' ').Trim(); Write-Output $s"
`) DO (
    set "movie_name=%%a"
)

ENDLOCAL & set "movie_name=%movie_name%"

cls
echo Copyright (C) YIFY / YTS
echo This script is an unofficial tool and relies entirely on their service.
echo.
echo.
echo Movie Name: [%movie_namee%]
echo Release Year: [%release_year%]
echo.
echo Is This Correct?
choice /C YN /M "Press Y for Yes, N for No"

if %ERRORLEVEL%==1 goto phase2

cls
echo Please Re-Enter The Following Details Correctly...
if %ERRORLEVEL%==2 goto phase1

:phase2
cls
echo Copyright (C) YIFY / YTS
echo This script is an unofficial tool and relies entirely on their service.
echo.
echo.
echo Finding the movie [%movie_namee%] released in [%release_year%]
echo.
curl -s "https://yts.mx/movies/%movie_name: =-%-%release_year%">movie.txt

if %ERRORLEVEL%==1 goto errorphase

find /I "Error! Not found (this page does not exist)" "movie.txt" >nul 2>&1
if %errorlevel%==0 goto errorphase

find /I "404, Oops! This page could not be found" "movie.txt" >nul 2>&1
if %errorlevel%==0 goto errorphase

find /I "not available" "movie.txt" >nul 2>&1
if %errorlevel%==0 goto notavailable

find "https://yts.mx/torrent/download/" movie.txt>movies.txt

REM Setting Variables to Define 'IF EXISTS' || where 1 means not available || 0 means available
SETLOCAL EnableDelayedExpansion

SET "filename=movies.txt"
SET "found_720p="
SET "found_1080p="
SET "found_2160p="
SET "pattern=1080p"

find "720p" "%filename%" > NUL 2>&1 && SET "found_720p=1"
find "1080p" "%filename%" > NUL 2>&1 && SET "found_1080p=1"
find "2160p" "%filename%" > NUL 2>&1 && SET "found_2160p=1"

REM --- 2. Build the dynamic CHOICE command ---
SET "choice_chars="
SET "choice_prompt=Found resolutions:"

REM We map 1->720p, 2->1080p, 3->2160p
IF DEFINED found_720p (
    SET "choice_chars=!choice_chars!1"
    SET "choice_prompt=!choice_prompt! [1] 720p"
)
IF DEFINED found_1080p (
    SET "choice_chars=!choice_chars!2"
    SET "choice_prompt=!choice_prompt! [2] 1080p"
)
IF DEFINED found_2160p (
    SET "choice_chars=!choice_chars!3"
    SET "choice_prompt=!choice_prompt! [3] 2160p"
)

REM --- DEBUG: See if the choice string was built ---
REM ECHO [Debug] Choice characters are: !choice_chars!

IF NOT DEFINED choice_chars (
    ECHO.
    ECHO None of the specified resolutions were found.
    GOTO :EOF
)

ECHO.
SET "choice_prompt=!choice_prompt!. Please choose:"
choice /C !choice_chars! /M "!choice_prompt!"
SET "choice_index=%ERRORLEVEL%"
SET /A char_index=choice_index-1

REM Use CALL to extract a substring using a dynamic numeric index
CALL SET "chosen_char=%%choice_chars:~%char_index%,1%%"

REM --- DEBUG: See what character was chosen ---
ECHO.
REM ECHO [Debug] Chosen character is: !chosen_char!
ECHO.

REM --- 4. Display the final selection ---
IF "!chosen_char!"=="1" SET "pattern=720p"
IF "!chosen_char!"=="2" SET "pattern=1080p"
IF "!chosen_char!"=="3" SET "pattern=2160p"

REM ECHO [Debug] Pattern is now: !pattern!

ENDLOCAL & set "pattern=%pattern%"
set "filename=movies.txt"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Select-String -Path '%filename%' -Pattern '%pattern%' -SimpleMatch | Select-Object -First 1).Line -replace '.*?(https?://\S+).*','$1'"`) do (
  set "final_link=%%A"
)

curl -L -o "%movie_name: =-%.torrent" %final_link%
%movie_name: =-%.torrent
echo.
echo.
echo You will be prompted to download the movie now. Thank You for using me.
goto cleaner


:notavailable
cls
echo Copyright (C) YIFY / YTS
echo This script is an unofficial tool and relies entirely on their service.
echo.
echo.
echo Sorry, But the %movie_namee% isn't yet available
goto cleaner

:errorphase
cls
Copyright (C) YIFY / YTS
echo This script is an unofficial tool and relies entirely on their service.
echo.
echo.
echo Sorry, Either the input is wrong, or the movie doesn't exist
goto cleaner

:cleaner
del movie.txt, movies.txt
goto quit

:quit
echo.
echo.
pause
exit
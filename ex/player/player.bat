@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
(CHCP 65001)>NUL
MODE 50, 11

IF not "%~1" == "" (
    GOTO :%~1
)
FOR /F %%A in ('ECHO PROMPT $E^| CMD') DO SET "ESC=%%A"

CALL :RADISH LOAD

ECHO Finished

EXIT /B

:LOAD
ECHO %ESC%[?25l%ESC%[38;2;255;255;255m%ESC%[6;21HLoading...
CALL :RADISH_WAIT

:MENU
TITLE Music Player
CD "tracks"
FOR %%M in (*.mp3) DO (
    SET /A "mus[num]+=1"
    CALL :RADISH_ADD "tracks\%%M" mus[!mus[num]!] TRACK
    SET "mus[disp]=!mus[disp]!%ESC%[5G%%M%ESC%[B"
)
SET /A "mus[cur]=4", "press=0"
SET "col[0]=66;224;245"
SET "col[1]=212;133;196"
SET "col[2]=132;172;232"
SET "col[3]=219;158;158"
SET "col[4]=45;89;92"

ECHO %ESC%[2J%ESC%[2;5HUse Down Arrow Key to Select Music%ESC%[4;5H%mus[disp]%%ESC%[!mus[cur]!;3H►
%RADISH_AUDIO_START% "P#%mus[1]%#100#0#100" %RADISH_AUDIO_END%

FOR /L %%# in () DO (
    SET /A "col=!RANDOM! %% 5"
    FOR %%C in (!col!) DO (
        ECHO %ESC%[38;2;!col[%%C]!m%ESC%[10;5H▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬%ESC%[0m
    )
    FOR /F "tokens=1-4 delims=." %%A in ("!CMDCMDLINE!") DO (
        SET "keys=%%D"
        IF not "!keys!" == "" (
            IF "!keys:-40-=!" == "!keys!" (
                SET "press=0"
            ) else IF "!press!" == "0" (
                SET /A "mus[prev]=mus[cur]", "mus[prev][adj]=mus[cur] - 3", "mus[cur]=((mus[cur] - 4 + 1) %% mus[num]) + 4", "mus[cur][adj]=mus[cur] - 3", "press=1"
                ECHO %ESC%[!mus[prev]!;3H %ESC%[!mus[cur]!;3H►
                FOR /F "tokens=1-2 delims=." %%G in ("!mus[prev][adj]!.!mus[cur][adj]!") DO (
                    %RADISH_AUDIO_START% "S#!mus[%%G]!" "P#!mus[%%H]!#100#0#100" %RADISH_AUDIO_END%
                )
            )
        ) else (
            SET "press=0"
        )
    )
    
)

:RADISH
SET /A "RADISH_ID=RADISH_INDEX=0" & SET "RADISH_AUDIO_START=ECHO " & SET "RADISH_AUDIO_END=>\\.\pipe\RADISH" & SET "RADISH_END=(TASKKILL /F /IM "RADISH.exe")>NUL & EXIT"
RADISH "%~nx0" %~1
GOTO :EOF
:RADISH_WAIT 
(ECHO/ > \\.\pipe\RADISH) 2>NUL && GOTO :EOF
(PATHPING 127.0.0.1 -n -q 1 -p 150)>NUL
GOTO :RADISH_WAIT
:RADISH_ADD <name> <var> <type> 
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL & SET /A "%2=RADISH_INDEX", "RADISH_INDEX+=1"
IF "%3" == "EFFECT" (%RADISH_AUDIO_START% "E#%~1" %RADISH_AUDIO_END%) else IF "%3" == "TRACK" (%RADISH_AUDIO_START% "T#%~1" %RADISH_AUDIO_END%) else IF "%3" == "OBJECT" (%RADISH_AUDIO_START% "O#%~1" %RADISH_AUDIO_END%)
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
:RADISH_CREATE_OBJ <index> <var> <x> <y>
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
SET /A "RADISH_ID-=1", "%2=RADISH_ID" & %RADISH_AUDIO_START% "C#%1#%3#%4" %RADISH_AUDIO_END% & (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
:RADISH_SET_OBS <x> <y>
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL & %RADISH_AUDIO_START% "X#%1#%2" %RADISH_AUDIO_END% & (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
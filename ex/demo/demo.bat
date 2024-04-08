@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
(CHCP 65001)>NUL
MODE 50, 25

IF not "%~1" == "" (
    GOTO :%~1
)
FOR /F %%A in ('ECHO PROMPT $E^| CMD') DO SET "ESC=%%A"

CALL :RADISH LOAD

ECHO Finished

EXIT /B

:LOAD
ECHO %ESC%[?25l%ESC%[38;2;255;255;255m%ESC%[12;21HLoading...
CALL :RADISH_WAIT

CALL :RADISH_SET_OBS p[x] p[y]

CALL :RADISH_ADD "Gibberish.mp3" gibber OBJECT
CALL :RADISH_ADD "Click.mp3" click EFFECT
CALL :RADISH_ADD "Water.mp3" water OBJECT
CALL :RADISH_ADD "LoveYou.mp3" menu TRACK
CALL :RADISH_ADD "Rain.mp3" rain TRACK
CALL :RADISH_ADD "CoffeeToGo.mp3" game TRACK

:MENU
TITLE Music Transition Menu
%RADISH_AUDIO_START% "P#%menu%#0#5#100" "P#%rain%#0#5#100" %RADISH_AUDIO_END%

:MENU_LOOP
SET "rain[disp]=%ESC%[38;2;120;181;207m"
FOR /L %%G in (1, 1, 10) DO (
    SET /A "rand[y]=!RANDOM! %% 25", "rand[x]=!RANDOM! %% 50"
    SET "rain[disp]=!rain[disp]!%ESC%[!rand[y]!;!rand[x]!H|"
)
FOR /F "tokens=1-4 delims=." %%A in ("!CMDCMDLINE!") DO (
    IF %%B EQU 12 (
        IF %%A GEQ 21 (
            IF %%A LEQ 28 (
                SET "col=234;123;24"
                IF %%C EQU 1 (
                    %RADISH_AUDIO_START% "P#%click%#0#5#50" "P#%menu%#100#1#0" "P#%rain%#100#1#0" %RADISH_AUDIO_END%
                    GOTO :GAME
                )
            ) else SET "dehover=1"
        ) else SET "dehover=1"
    ) else SET "dehover=1"
    IF "!dehover!" == "1" (
        SET "col=255;255;255"
        SET "dehover=0"
    )
)
ECHO %ESC%[2J!rain[disp]!%ESC%[38;2;255;255;255m%ESC%[11;21H^<- DEMO -^>%ESC%[38;2;!col!m%ESC%[13;22H[ PLAY ]
GOTO :MENU_LOOP

:GAME
TITLE Move Mouse for Spatial Audio

CALL :RADISH_CREATE_OBJ %water% water[obj] 12 10
CALL :RADISH_CREATE_OBJ %gibber% gibber[obj] 30 20

SET "col=255;255;255"
SET /A "p[x]=1", "p[y]=1"

%RADISH_AUDIO_START% "P#%game%#0#7#100" "P#%water[obj]%#50#1#50" "P#%gibber[obj]%#100#1#100" %RADISH_AUDIO_END%

:GAME_LOOP
ECHO %ESC%[2J%ESC%[38;2;245;239;213m%ESC%[!p[y]!;!p[x]!H☻%ESC%[10;12H%ESC%[48;2;136;225;235m%ESC%[38;2;255;255;255m~%ESC%[0m%ESC%[38;2;178;156;219m%ESC%[20;30H☻%ESC%[38;2;!col!m%ESC%[2;22H[ BACK ]
FOR /F "tokens=1-4 delims=." %%A in ("!CMDCMDLINE!") DO (
    SET /A "p[x]=%%A + 1", "p[y]=%%B + 1"
    IF %%B EQU 1 (
        IF %%A GEQ 21 (
            IF %%A LEQ 28 (
                SET "col=234;123;24"
                IF %%C EQU 1 (
                    %RADISH_AUDIO_START% "P#%click%#0#5#50" "P#%game%#100#1#0" "P#%water[obj]%#100#1#0" "P#%gibber[obj]%#100#1#0" %RADISH_AUDIO_END%
                    GOTO :MENU
                )
            ) else SET "dehover=1"
        ) else SET "dehover=1"
    ) else SET "dehover=1"
    IF "!dehover!" == "1" (
        SET "col=255;255;255"
        SET "dehover=0"
    )
)
GOTO :GAME_LOOP

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
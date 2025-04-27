@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
MODE 30, 20
(CHCP 65001)>NUL
IF not "%~1" == "" (
    GOTO :%~1
)

FOR /F %%A in ('ECHO PROMPT $E^| CMD') DO SET "ESC=%%A"

TITLE  
ECHO %ESC%[?25l%ESC%[8;11H%ESC%[38;2;201;187;123m(=%ESC%[38;2;87;105;53m^^%ESC%[38;2;201;187;123m-ω-%ESC%[38;2;87;105;53m^^%ESC%[38;2;201;187;123m=)%ESC%[38;2;255;255;255m%ESC%[9;2HClick Symbols to Get Points%ESC%[10;11HPress (A)
(PAUSE)>NUL

CALL :RADISH LOAD

ECHO %ESC%[?25l%ESC%[38;2;255;255;255m%ESC%[9;9HGreat Job :D%ESC%[10;11HPress (A)
(PAUSE)>NUL
EXIT /B

:LOAD

ECHO %ESC%[2J%ESC%[9;12HLoading...
CALL :RADISH_WAIT
CALL :RADISH_ADD "Relax Time.mp3" track TRACK

:GAME
SET "disp= "
SET "points=4#5#95#♥ 6#7#205#♣ 8#9#305#♠ 10#7#570#♣ 12#12#805#♥ 9#7#835#♠ 10#7#865#♣ 11#7#1265#♥  16#17#1365#♠  19#5#1475#♠ 11#9#1585#♥  10#9#1700#♣ 13#10#1845#♠ 12#6#1955#♥ 9#7#1995#♣ 11#8#2205#♣ 15#2#2405#♠ 10#7#2805#♣ 9#7#2905#♥ E#E#3005"
%RADISH_AUDIO% "P#%track%#100#0#100"
 
SET "start[t]=%time: =0%"
SET "start=!start[t]:%time:~8,1%=%%100)*100+1!"
SET "score=0"
ECHO %ESC%[2J%ESC%[2;2HScore : %score%
FOR /L %%# in () DO (
    SET "end[t]=!time: =0!"
    SET "end=!end[t]:%time:~8,1%=%%100)*100+1!"
    SET /A "elap=((((10!end:%time:~2,1%=%%100)*60+1!%%100)-((((10!start:%time:~2,1%=%%100)*60+1!%%100), elap-=(elap>>31)*24*60*60*100"
    FOR /F "tokens=1-3 delims=." %%A in ("!CMDCMDLINE!") DO (
        SET /A "d[y]=%%B+1", "d[x]=%%A+1"
        IF "%%C" == "1" (
            FOR %%G in (" !d[y]!#!d[x]!#") DO (
                IF not "!disp!" == "!disp:%%~G=!" (
                    SET /A "score+=1"
                    ECHO %ESC%[!d[y]!;!d[x]!H☼%ESC%[2;2HScore : !score!
                )
            )
        )
    )
    SET "new[disp]= "
    FOR %%Q in (!disp!) DO (
        FOR /F "tokens=1-4 delims=#" %%A in ("%%Q") DO (
            IF %%D LEQ !elap! (
                ECHO %ESC%[%%A;%%BH 
            ) else (
                SET "new[disp]=!new[disp]! %%A#%%B#%%C#%%D"
            )
        )
    )
    SET "disp=!new[disp]!"
    FOR /F "tokens=1-4,* delims=# " %%A in ("!points!") DO (
        IF %%C LEQ !elap! ( 
            IF "%%A" == "E" (
                %RADISH_END%
            )
            ECHO %ESC%[%%A;%%BH%%D
            SET /A "d[num]=elap + 100"
            SET "disp=!disp! %%A#%%B#%%C#!d[num]!"
            SET "points=%%E"
        )
    )
)

:RADISH
SET /A "RADISH_ID=RADISH_INDEX=0" & SET "RADISH_AUDIO=>\\.\pipe\RADISH ECHO " & SET "RADISH_END=(TASKKILL /F /IM "RADISH.exe")>NUL & EXIT"
RADISH "%~nx0" %~1
GOTO :EOF
:RADISH_WAIT 
(ECHO/ > \\.\pipe\RADISH) 2>NUL && GOTO :EOF
(PATHPING 127.0.0.1 -n -q 1 -p 150)>NUL
GOTO :RADISH_WAIT
:RADISH_ADD <name> <var> <type> 
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL & SET /A "%2=RADISH_INDEX", "RADISH_INDEX+=1"
IF "%3" == "EFFECT" (%RADISH_AUDIO% "E#%~1") else IF "%3" == "TRACK" (%RADISH_AUDIO% "T#%~1") else IF "%3" == "OBJECT" (%RADISH_AUDIO% "O#%~1")
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
:RADISH_CREATE_OBJ <index> <var> <x> <y>
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
SET /A "RADISH_ID-=1", "%2=RADISH_ID" & %RADISH_AUDIO% "C#%1#%3#%4" & (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
:RADISH_SET_OBS <x> <y>
(PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL & %RADISH_AUDIO% "X#%1#%2" & (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
GOTO :EOF
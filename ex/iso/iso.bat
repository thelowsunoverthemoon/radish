@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
MODE 60, 22
(CHCP 65001)>NUL
IF not "%~1" == "" (
    GOTO :%~1
)
CALL :MACROS

CALL :RADISH LOAD

ECHO %ESC%[2J%ESC%[38;2;255;255;255m%ESC%[11;26HFinished...

(PAUSE)>NUL

EXIT /B

:LOAD

ECHO %ESC%[?25l%ESC%[38;2;255;255;255m%ESC%[11;26HLoading...

CALL :RADISH_WAIT

SET "relic[0]=%bk:n=1%⌐╩¬%bk:n=2%%up:n=1%█"
SET "relic[1]=%bk:n=1%⌐╩¬%bk:n=2%%up:n=1%▓"
SET "relic[2]=%bk:n=1%⌐╩¬%bk:n=2%%up:n=1%▒"
SET "ruin[0]=▀
SET "ruin[1]=▀%bk:n=1%%up:n=1%█"
SET "ruin[2]=█"
SET ruins="0;8;19" "0;8;20" "1;8;21" "0;12;20" "2;10;28" "0;6;47" "1;16;40"

FOR %%R in (%ruins%) DO (
    FOR /F "tokens=1-3 delims=;" %%A in ("%%~R") DO (
        SET "ruins[disp]=!ruins[disp]!%ESC%[%%B;%%CH!ruin[%%A]!"
        SET "tile[%%B][%%C]=1"
    )
)
SET /A "relic[y]=14", "relic[x]=30"
SET "tile[%relic[y]%][%relic[x]%]=1"
SET /A "dim=12", "grid[x]=dim", "grid[y]=dim", "grid[bk]=(grid[x] * 3) + 1", "margin=20 - grid[x]", "x[u]=20", "y[u]=6", "pressed=relic[num]=0"
FOR /L %%X in (1, 1, %grid[x]%) DO (
    SET "grid[xlen]=!grid[xlen]!/_/"
    SET "grid[tlen]=!grid[tlen]!__ "
)
SET "grid[disp]=!nx:n=%grid[y]%!%grid[tlen]%%dn:n=1%!bk:n=%grid[bk]%!"
FOR /L %%Y in (1, 1, %grid[y]%) DO (
    SET "grid[disp]=!grid[disp]!%grid[xlen]%%dn:n=1%!bk:n=%grid[bk]%!"
)

CALL :RADISH_SET_OBS x[a] y[a]
CALL :RADISH_ADD "A Hunger Too Deep.mp3" background TRACK
CALL :RADISH_ADD "footstep.mp3" footstep EFFECT
CALL :RADISH_ADD "whisper.mp3" whisper OBJECT

SET /A "y[r]=relic[y] - 5", "x[r]=((relic[x] - (dim - y[r]) - margin) / 3) + 1"
CALL :RADISH_CREATE_OBJ %whisper% whisper[obj] %x[r]% %y[r]%
%RADISH_AUDIO% "P#%background%#100#0#100" "P#%whisper[obj]%#100#0#100"

:GAME
TITLE Press WASD to Move, Q to Quit
ECHO %ESC%[?25l 
FOR /L %%# in () DO (
    FOR %%R in (!relic[num]!) do (
        ECHO %ESC%[2J%col:c=138;130;107%%ESC%[5;%margin%H%grid[disp]%%ESC%[1B%ESC%[%margin%GRuins of a Ancient Temple%col:c=158;132;77%%ruins[disp]%%col:c=68;117;135%%ESC%[%relic[y]%;%relic[x]%H!relic[%%R]!%ESC%[!y[u]!;!x[u]!H%col:c=193;113;222%▀%bk:n=1%%up:n=1%%col:c=207;91;183%▲
    )
    FOR /F "tokens=1,4 delims=." %%A in ("!CMDCMDLINE!") DO (
        IF "%%B" == "" (
            SET "pressed=0"
        ) else IF "%%B" == "-81-" (
            %RADISH_END%
        ) else IF not "%%B" == "!pressed!" (
            SET "pressed=0"
        )
        IF "!pressed!" == "0" ( IF not "!mv[%%B]!" == "" (
            (SET /A "y[t]=y[u]", "x[t]=x[u]", !mv[%%B]:#=t!, "1/((((5-y[t])>>31)&1)&(((y[t]-(grid[y]+6))>>31)&1)&((((((grid[y]-(y[t]-5)))+%margin%)-x[t])>>31)&1)&(((x[t]-((((grid[y]-(y[t]-5)))+%margin%)+(3*grid[x])))>>31)&1))" 2>NUL) && (
                IF not defined tile[!y[t]!][!x[t]!] (
                    %RADISH_AUDIO% "P#%footstep%#100#0#100"
                    SET /A "y[u]=y[t]", "x[u]=x[t]", "y[a]=y[u] - 5", "x[a]=((x[u] - (dim - y[a]) - margin) / 3) + 1"
                    SET "pressed=%%B"
                )
            )
        ))
    )
    SET /A "relic[num]=(relic[num] + 1) %% 3"
)

:MACROS
FOR /F %%A in ('ECHO PROMPT $E^| CMD') DO SET "ESC=%%A"
SET mv[-87-]="y[#]-=1","x[#]+=1"
SET mv[-65-]="x[#]-=3"
SET mv[-83-]="y[#]+=1","x[#]-=1"
SET mv[-68-]="x[#]+=3"
SET up=%ESC%[nA
SET dn=%ESC%[nB
SET bk=%ESC%[nD
SET nx=%ESC%[nC
SET col=%ESC%[38;2;cm
GOTO :EOF

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
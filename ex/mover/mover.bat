@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

MODE 50, 25
TITLE Mover : Q to Quit
(CHCP 65001)>NUL

IF not "%~1" == "" (
    GOTO :%~1
)

CALL :MACROS

SET /A "char[y]=to[y]=12", "char[x]=to[x]=24", "to[cur]=0", "char[cur]=1"
SET "spr[char]=█ ▓ ▒ ▓ █"
SET "spr[mov]=%bk:n=1%─┼─%bk:n=2%%up:n=1%│%bk:n=1%%dn:n=2%│ %bk:n=1%├┼┤%bk:n=2%%up:n=1%┬%bk:n=1%%dn:n=2%┴ ┼ •"

FOR %%G in (char mov) DO (
    FOR %%D in (!spr[%%G]!) DO (
        SET /A "spr[num][%%G]+=1"
        SET "spr[%%G][!spr[num][%%G]!]=%%D"
    )
    SET /A "spr[num][%%G]+=1"
)

ECHO %ESC%[12;13HRight Click to Move Character%ESC%[13;19HPress any Key%ESC%[?25l
(PAUSE)>NUL

CALL :RADISH_PLAY 20 10 2 GAME

ECHO %ESC%[2J%ESC%[12;17HThanks for Playing%ESC%[13;19HPress any Key
(PAUSE)>NUL
EXIT /B

:GAME

%RADISH_START%

FOR /L %%# in () DO (
    %RADISH_START_PARSE%
        IF "%%A" == "M" (
            IF "%%D" == "2" (
                SET /A "to[x]=%%B + 1", to[y]=%%C + 1", "to[cur]=1"
            )
        ) else IF "%%B" == "81" (
            %RADISH_END%
        )
    %RADISH_END_PARSE%
    IF !to[x]! NEQ !char[x]! (
        IF !char[x]! GTR !to[x]! (
            SET /A "char[x]-=1"
        ) else (
            SET /A "char[x]+=1"
        )
    )
    IF !to[y]! NEQ !char[y]! (
        IF !char[y]! GTR !to[y]! (
            SET /A "char[y]-=1"
        ) else (
            SET /A "char[y]+=1"
        )
    )
    FOR /F "tokens=1-2" %%T in ("!char[cur]! !to[cur]!") DO (
        ECHO %ESC%[2J%ESC%[!char[y]!;!char[x]!H!spr[char][%%T]!%ESC%[!to[y]!;!to[x]!H!spr[mov][%%U]!
    )
    IF !to[cur]! NEQ 0 (
        SET /A "to[cur]=(to[cur] + 1) %% spr[num][mov]"
    )
    
    SET /A "char[cur]=(char[cur] + 1) %% spr[num][char]"
    IF !char[cur]! EQU 0 (
        SET "char[cur]=1"
    )

)

:MACROS
FOR /F %%A in ('ECHO PROMPT $E^| CMD') DO SET "ESC=%%A"
SET col=%ESC%[38;2;cm
SET bcl=%ESC%[48;2;cm
SET up=%ESC%[nA
SET dn=%ESC%[nB
SET bk=%ESC%[nD
SET nx=%ESC%[nC
GOTO :EOF

:RADISH_PLAY
DEL /F /Q "RADISH_CURSOR" 2>NUL&SET "RADISH_START_PARSE=SET /P "RADISH_INPUT="^&FOR %%? in (^!RADISH_INPUT^!)DO (FOR /F "tokens=1-7 delims=." %%A in ("%%?")DO ("&SET "RADISH_END_PARSE=))&SET "RADISH_INPUT=""
SET "RADISH_END=(TASKKILL /F /IM POWERSHELL.exe)>NUL&EXIT"
SET RADISH_START=START /B POWERSHELL -NoProfile -ExecutionPolicy Unrestricted ^
$Source = 'using System;using System.Text;using System.Runtime.InteropServices;public class Program{public static void Run(){var stdout=GetStdHandle(STD_OUTPUT_HANDLE);CONSOLE_SCREEN_BUFFER_INFO buf=new CONSOLE_SCREEN_BUFFER_INFO();while(true){GetConsoleScreenBufferInfo(stdout,ref buf);System.IO.File.WriteAllText("""RADISH_CURSOR""", buf.dwCursorPositionY.ToString());System.Threading.Thread.Sleep(10);}}  ^
private const int STD_OUTPUT_HANDLE=-11;[DllImport("""kernel32.dll""",SetLastError=true)]private static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("""kernel32.dll""",SetLastError=true)]private static extern bool GetConsoleScreenBufferInfo(IntPtr hConsoleOutput,ref CONSOLE_SCREEN_BUFFER_INFO ConsoleScreenBufferInfo);private struct CONSOLE_SCREEN_BUFFER_INFO{public readonly short dwSizeX;public readonly short dwSizeY;public readonly short dwCursorPositionX;public readonly short dwCursorPositionY;public readonly ushort wAttributes;public readonly short x;public readonly short y;public readonly short i;public readonly short j;public readonly short dwMaximumWindowSizeX;public readonly short dwMaximumWindowSizeY;}}';  ^
Add-Type -TypeDefinition $Source;[Program]::Run()
POWERSHELL -NoProfile -ExecutionPolicy Unrestricted ^
While (^^^!(Test-Path "RADISH_CURSOR" -ErrorAction SilentlyContinue)) {};  ^
$Mouse='if(records[i].EventType==MOUSE_EVENT){FileStream curStm=new FileStream("""RADISH_CURSOR""", FileMode.Open, FileAccess.Read, FileShare.ReadWrite);StreamReader curRdr = new StreamReader(curStm);while(^^^!curRdr.EndOfStream){cursor=Int32.Parse(curRdr.ReadLine());}curStm.Close();curRdr.Close();int yAdj=records[i].MouseEvent.y;if(cursor^>Console.WindowHeight-1){yAdj-=(cursor-(Console.WindowHeight-1));}output.Append("""M."""+records[i].MouseEvent.x+"""."""+yAdj+"""."""+records[i].MouseEvent.dwButtonState+"""."""+records[i].MouseEvent.dwControlKeyState+"""."""+records[i].MouseEvent.dwEventFlags);if(records[i].MouseEvent.dwEventFlags==MOUSE_EVENT_WHEEL_VERT^|^|records[i].MouseEvent.dwEventFlags==MOUSE_EVENT_WHEEL_HORZ){output.Append("""."""+Math.Sign((short)(records[i].MouseEvent.dwButtonState^>^>16)));}output.Append(""" """);}';  ^
$Key='if(records[i].EventType==KEY_EVENT){output.Append("""K."""+records[i].KeyEvent.wVirtualKeyCode+"""."""+records[i].KeyEvent.bKeyDown+"""."""+records[i].KeyEvent.dwControlKeyState+""" """);}';  ^
$Every=%1;$Max=%2;$Type=%3;if($Type -eq 0){$Detect=$Mouse}elseif($Type -eq 1){$Detect=$Key}else{$Detect=$Mouse+'else '+$Key;}  ^
$Source='using System;using System.Text;using System.IO;using System.Runtime.InteropServices;public class Program{public static void Run(){var cursor=0;var nRead=0+cursor;uint numEvent=0;var records=new INPUT_RECORD['+$Max+'];var stdin=GetStdHandle(STD_INPUT_HANDLE);uint mode=0;GetConsoleMode(stdin,out mode);SetConsoleMode(stdin,ENABLE_MOUSE_INPUT^|ENABLE_EXTENDED_FLAGS^|(mode^&~ENABLE_QUICK_EDIT_MODE));StringBuilder output=new StringBuilder();while(true){GetNumberOfConsoleInputEvents(stdin,out numEvent);if(numEvent^^^!=0){ReadConsoleInputW(stdin,records,records.Length,ref nRead);output.Length=0;for(var i=0;i^<nRead;i++){'+$Detect+'}if(output.Length^^^!=0){Console.WriteLine(output.ToString());}else{Console.WriteLine("""""");}}else{Console.WriteLine("""""");}  ^
System.Threading.Thread.Sleep('+$Every+');}}private const int STD_INPUT_HANDLE=-10;private const uint ENABLE_MOUSE_INPUT=0x0010;private const uint ENABLE_EXTENDED_FLAGS=0x0080;private const uint ENABLE_QUICK_EDIT_MODE=0x0040;private const short MOUSE_EVENT_WHEEL_VERT=0x0004;private const short MOUSE_EVENT_WHEEL_HORZ=0x0008;private const short MOUSE_EVENT=0x0002;private const short KEY_EVENT=0x0001;[DllImport("""kernel32.dll""",SetLastError=true)]static extern bool GetConsoleMode(IntPtr hConsoleHandle,out uint lpMode);[DllImport("""kernel32.dll""",SetLastError=true)]static extern bool SetConsoleMode(IntPtr hConsoleHandle,uint dwMode);[DllImport("""kernel32.dll""", SetLastError = true)]private static extern bool GetNumberOfConsoleInputEvents(IntPtr hConsoleInput,out uint lpcNumberOfEvents);  ^
[DllImport("""kernel32.dll""",SetLastError=true)]private static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("""kernel32.dll""",SetLastError=true)]private static extern bool ReadConsoleInputW(IntPtr hConsoleInput,[Out]INPUT_RECORD[]lpBuffer,int nLength,ref int lpNumberOfEventsRead);[StructLayout(LayoutKind.Explicit)]private struct INPUT_RECORD{[FieldOffset(0)]public readonly short EventType;[FieldOffset(4)]public MOUSE_EVENT_RECORD MouseEvent;[FieldOffset(4)]public KEY_EVENT_RECORD KeyEvent;}[StructLayout(LayoutKind.Sequential)]private struct MOUSE_EVENT_RECORD{public readonly short x;  ^
public readonly short y;public readonly uint dwButtonState;public readonly uint dwControlKeyState;public readonly uint dwEventFlags;}[StructLayout(LayoutKind.Sequential)]private struct KEY_EVENT_RECORD{public readonly uint bKeyDown;public readonly ushort wRepeatCount;public readonly ushort wVirtualKeyCode;public readonly ushort wVirtualScanCode;public readonly char UnicodeChar;public readonly uint dwControlKeyState;}}';  ^
Add-Type -TypeDefinition $Source;[Program]::Run() | "%~F0" %4
GOTO :EOF

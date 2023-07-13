using System;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;

public class Program {
  public static void Run() {
    
    var cursor = 0;
    // needed since treat warning as error is enabled in compiler, and -CompilerOptions is not availible in all Powershell versions
    var nRead = 0 + cursor;
    uint numEvent = 0;
    // max parameter
    var records = new INPUT_RECORD['+$Max+'];
    var stdin = GetStdHandle(STD_INPUT_HANDLE);
    StringBuilder output = new StringBuilder();
    
    uint mode = 0;
    GetConsoleMode(stdin, out mode);
    SetConsoleMode(stdin, ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS | (mode & ~ENABLE_QUICK_EDIT_MODE));
    
    while (true) {
      GetNumberOfConsoleInputEvents(stdin, out numEvent);
    
      if (numEvent != 0) {
        ReadConsoleInputW(stdin, records, records.Length, ref nRead);
        output.Length = 0;
        for (var i = 0; i ^ < nRead; i++) {
          // detection parameter
          '+$Detect+'
        }
        if (output.Length != 0) {
          Console.WriteLine(output.ToString());
        } else {
          Console.WriteLine("");
        }
      } else {
        Console.WriteLine("");
      }
      
      // every paramter
      System.Threading.Thread.Sleep('+$Every+');
    }
  }
  
  private const int STD_INPUT_HANDLE = -10;
  private const uint ENABLE_MOUSE_INPUT = 0x0010;
  private const uint ENABLE_EXTENDED_FLAGS = 0x0080;
  private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
  private const short MOUSE_EVENT_WHEEL_VERT = 0x0004;
  private const short MOUSE_EVENT_WHEEL_HORZ = 0x0008;
  private const short MOUSE_EVENT = 0x0002;
  private const short KEY_EVENT = 0x0001;
  
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
  [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
  [DllImport("kernel32.dll", SetLastError = true)] private static extern bool GetNumberOfConsoleInputEvents(IntPtr hConsoleInput, out uint lpcNumberOfEvents); 
  [DllImport("kernel32.dll", SetLastError = true)] private static extern IntPtr GetStdHandle(int nStdHandle);
  [DllImport("kernel32.dll", SetLastError = true)] private static extern bool ReadConsoleInputW(IntPtr hConsoleInput, [Out] INPUT_RECORD[] lpBuffer, int nLength, ref int lpNumberOfEventsRead);
  
  [StructLayout(LayoutKind.Explicit)] private struct INPUT_RECORD {
    [FieldOffset(0)] public readonly short EventType;
    [FieldOffset(4)] public MOUSE_EVENT_RECORD MouseEvent;
    [FieldOffset(4)] public KEY_EVENT_RECORD KeyEvent;
  }
  
  [StructLayout(LayoutKind.Sequential)] private struct MOUSE_EVENT_RECORD {
    public readonly short x;
    public readonly short y;
    public readonly uint dwButtonState;
    public readonly uint dwControlKeyState;
    public readonly uint dwEventFlags;
  }
  
  [StructLayout(LayoutKind.Sequential)] private struct KEY_EVENT_RECORD {
    public readonly uint bKeyDown;
    public readonly ushort wRepeatCount;
    public readonly ushort wVirtualKeyCode;
    public readonly ushort wVirtualScanCode;
    public readonly char UnicodeChar;
    public readonly uint dwControlKeyState;
  }
  
}

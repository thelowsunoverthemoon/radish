using System;
using System.Text;
using System.Runtime.InteropServices;

public class Program {
  public static void Run() {
    
      var stdout = GetStdHandle(STD_OUTPUT_HANDLE);
      CONSOLE_SCREEN_BUFFER_INFO buf = new CONSOLE_SCREEN_BUFFER_INFO();
    
      while (true) {
        GetConsoleScreenBufferInfo(stdout, ref buf);
        System.IO.File.WriteAllText("RADISH_CURSOR", buf.dwCursorPositionY.ToString());
        System.Threading.Thread.Sleep(10);
      }
    
  }
    
  private const int STD_OUTPUT_HANDLE = -11;
  
  [DllImport("kernel32.dll", SetLastError = true)] private static extern IntPtr GetStdHandle(int nStdHandle);
  [DllImport("kernel32.dll", SetLastError = true)] private static extern bool GetConsoleScreenBufferInfo(IntPtr hConsoleOutput, ref CONSOLE_SCREEN_BUFFER_INFO ConsoleScreenBufferInfo);
  
  private struct CONSOLE_SCREEN_BUFFER_INFO {
    public readonly short dwSizeX;
    public readonly short dwSizeY;
    public readonly short dwCursorPositionX;
    public readonly short dwCursorPositionY;
    public readonly ushort wAttributes;
    public readonly short x;
    public readonly short y;
    public readonly short i;
    public readonly short j;
    public readonly short dwMaximumWindowSizeX;
    public readonly short dwMaximumWindowSizeY;
  }
  
}

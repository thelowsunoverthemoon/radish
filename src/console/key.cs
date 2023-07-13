if (records[i].EventType==KEY_EVENT) {
  output.Append("K." + records[i].KeyEvent.wVirtualKeyCode + "." + records[i].KeyEvent.bKeyDown + "." + records[i].KeyEvent.dwControlKeyState + " ");
}

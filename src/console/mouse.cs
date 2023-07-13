if (records[i].EventType == MOUSE_EVENT) {
  FileStream curStm = new FileStream("RADISH_CURSOR", FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
  StreamReader curRdr = new StreamReader(curStm);
  while(!curRdr.EndOfStream) {
    cursor=Int32.Parse(curRdr.ReadLine());
  }
  curStm.Close();
  curRdr.Close();
  int yAdj = records[i].MouseEvent.y;
  if(cursor > Console.WindowHeight - 1) {
    yAdj -= (cursor-(Console.WindowHeight-1));
  }
  output.Append("M." + records[i].MouseEvent.x + "." + yAdj + "." + records[i].MouseEvent.dwButtonState + "." + records[i].MouseEvent.dwControlKeyState + "." + records[i].MouseEvent.dwEventFlags);
  if (records[i].MouseEvent.dwEventFlags == MOUSE_EVENT_WHEEL_VERT || records[i].MouseEvent.dwEventFlags == MOUSE_EVENT_WHEEL_HORZ) {
    output.Append("." + Math.Sign((short)(records[i].MouseEvent.dwButtonState >> 16)));
  }
  output.Append(" ");
};

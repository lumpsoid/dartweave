void writeToBuffer(StringBuffer buffer, String body, {bool ln = false}) {
  if (ln) {
    buffer.writeln(body);
  } else {
    buffer.write(body);
  }
}

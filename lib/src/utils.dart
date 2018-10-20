String intToHex(int i) {
  var hexstr = i.toRadixString(16);
  return hexstr.length % 2 == 0 ? hexstr : '0${hexstr}';
}

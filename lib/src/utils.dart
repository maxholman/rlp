import 'dart:typed_data';

import 'package:convert/convert.dart';

/// Converts an integer into a hex string
String intToHex(int i) {
  var hexStr = i.toRadixString(16);
  return hexStr.length % 2 == 0 ? hexStr : '0${hexStr}';
}

/// Merge/Concatentate two Lists as a Uint8List
Uint8List mergeAsUint8List(List<int> a, List<int> b) {
  var output = BytesBuilder();
  output.add(a);
  output.add(b);
  return output.toBytes();
}

/// Safely parses the String to int
int safeParseInt(String v, [int? base]) {
  if (v.startsWith('00')) {
    throw FormatException('Invalid RLP: extra zeros');
  }

  return int.parse(v, radix: base);
}

/// Encode an int into bytes
Uint8List encodeInt(int i) {
  if (i == 0) {
    return Uint8List(0);
  } else {
    var hexStr = intToHex(i);
    return Uint8List.fromList(hex.decoder.convert(hexStr));
  }
}

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

/// Decodes the given [String] to [Uint8List]
Uint8List decodeString(String string) {
  return Uint8List.fromList(string.codeUnits);
}

/// Safely parses the String to int
int safeParseInt(String v, [int? base]) {
  if (v.startsWith('00')) {
    throw FormatException('Invalid RLP: extra zeros');
  }

  return int.parse(v, radix: base);
}

/// Checks whether the give string is hex or not
bool isHexString(String value, {int length = 0}) {
  if (!RegExp('^0x[0-9A-Fa-f]*\$').hasMatch(value)) {
    return false;
  }

  if (length > 0 && value.length != 2 + 2 * length) {
    return false;
  }

  return true;
}

/// Strips the hex prefix from given string. 
/// 
/// 0x40 -> 40
String stripHexPrefix(String str) {
  return isHexPrefixed(str) ? str.substring(2) : str;
}

/// Checks whether the given string has hex prefix('0x') or not.
bool isHexPrefixed(String str) {
  return str.substring(0, 2) == '0x';
}

/// Pads a [String] to have an even length
String padToEven(String value) {
  var a = value;

  if (a.length % 2 == 1) {
    a = "0$a";
  }

  return a;
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

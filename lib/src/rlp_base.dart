import 'package:convert/convert.dart';
import 'package:rlp/src/pointycastle-utils.dart';
import 'package:rlp/src/utils.dart';

/// Encode an int into bytes
List<int> _encodeInt(int i) {
  if (i == 0) {
    return [];
  } else {
    var hexstr = intToHex(i);
    return hex.decoder.convert(hexstr);
  }
}

class Address {
  String address;

  Address(this.address);

  List<int> toList() {
    return hex.decode(address.substring(2));
  }

  String toString() {
    return this.address;
  }
}

class Rlp {
  static List<int> maybeEncodeLength(List<int> input) {
    if (input.length == 1 && input.first < 0x80) {
      return input;
    } else {
      return encodeLength(input.length, 0x80)..addAll(input);
    }
  }

  static List<int> encode(dynamic input) {
    if (input is List) {
      List<int> output = input.fold([], (accum, i) {
        return accum..addAll(encode(i));
      });
      return encodeLength(output.length, 0xc0)..addAll(output);
    } else {
      return maybeEncodeLength(input is Address
          ? input.toList()
          : input is String
              ? input.codeUnits
              : input is int
                  ? _encodeInt(input)
                  : input is BigInt
                      ? encodeBigInt(input)
                      : throw ('Invalid Input Type'));
    }
  }

  static List<int> encodeLength(int len, int offset) {
    if (len < 56) {
      return [len + offset];
    } else {
      var binary = toBinary(len);
      return [binary.length + offset + 55]..addAll(binary);
    }
  }

  static List<int> toBinary(int x) {
    if (x == 0) {
      return [];
    } else {
      return toBinary(x ~/ 256)..add(x % 256);
    }
  }
}

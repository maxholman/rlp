import 'dart:typed_data';

import 'package:rlp/src/bigint-codec.dart';
import 'package:rlp/src/utils.dart';

import 'address.dart';

/// RLP Recursive Length Prefix (Encoder only)
class Rlp {

  static Uint8List _maybeEncodeLength(Uint8List input) {
    if (input.length == 1 && input.first < 0x80) {
      return input;
    } else {
      return mergeAsUint8List(_encodeLength(input.length, 0x80), input);
    }
  }

  static Uint8List _encodeNonListType(dynamic input) {
    if (input is Address) {
      return input.toBytes();
    }

    if (input is String) {
      return Uint8List.fromList(input.codeUnits);
    }

    if (input is int) {
      return encodeInt(input);
    }

    if (input is BigInt) {
      return encodeBigInt(input);
    }

    throw ('Invalid Input Type');
  }

  static Uint8List _encodeLength(int len, int offset) {
    if (len < 56) {
      return Uint8List.fromList([len + offset]);
    } else {
      var binary = _toBinary(len);
      return mergeAsUint8List([binary.length + offset + 55], binary);
    }
  }

  static Uint8List _toBinary(int x) {
    if (x == 0) {
      return Uint8List(0);
    } else {
      return mergeAsUint8List(_toBinary(x ~/ 256), [x % 256]);
    }
  }

  /// Encodes the input as a Uint8List
  static Uint8List encode(dynamic input) {
    if (input is List) {
      var output = BytesBuilder();
      input.forEach((i) {
        return output.add(encode(i));
      });
      return mergeAsUint8List(
          _encodeLength(output.length, 0xc0), output.toBytes());
    }

    return Rlp._maybeEncodeLength(Rlp._encodeNonListType(input));
  }
}

import 'dart:typed_data';

import 'package:convert/convert.dart';
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
    if (input is Uint8List) return input;
    if (input is List<int>) return Uint8List.fromList(input);
    if (input is Address) {
      return input.toBytes();
    }

    if (input is String) {
      if (isHexString(input)) {
        return Uint8List.fromList(hex.decode(padToEven(stripHexPrefix(input))));
      }
      return decodeString(input);
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

  /// Decodes the Uint8List
  static List<dynamic> decode(Uint8List input) {
    if (input.length == 0) {
      return <dynamic>[];
    }

    Uint8List inputBuffer = _encodeNonListType(input);
    Decoded decoded = _decode(inputBuffer);

    if (decoded.remainder.length != 0) {
      throw FormatException('invalid remainder');
    }

    return decoded.data;
  }

  static Decoded _decode(Uint8List input) {
    int firstByte = input[0];
    if (firstByte <= 0x7f) {
      // A single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
      return Decoded(input.sublist(0, 1), input.sublist(1));
    } else if (firstByte <= 0xb7) {
      // String is 0-55 bytes long. A single byte with value 0x80 plus the length
      // of the string followed by the string.

      // The range of the first byte is [0x80, 0xb7]
      int length = firstByte - 0x7f;

      // Set 0x80 null to 0
      Uint8List data =
          firstByte == 0x80 ? Uint8List(0) : input.sublist(1, length);

      if (length == 2 && data[0] < 0x80) {
        throw FormatException('Invalid RLP encoding: byte must be less 0x80');
      }

      return Decoded(data, input.sublist(length));
    } else if (firstByte <= 0xbf) {
      int llength = firstByte - 0xb6;
      int length = safeParseInt(hex.encode(input.sublist(1, llength)), 16);
      Uint8List data = input.sublist(llength, length + llength);
      if (data.length < length) {
        throw FormatException('Invalid RLP');
      }

      return Decoded(data, input.sublist(length + llength));
    } else if (firstByte <= 0xf7) {
      // A list between  0-55 bytes long
      List<dynamic> decoded = <dynamic>[];
      int length = firstByte - 0xbf;

      Uint8List innerRemainder = input.sublist(1, length);

      while (innerRemainder.length > 0) {
        Decoded d = _decode(innerRemainder);
        decoded.add(d.data);
        innerRemainder = d.remainder;
      }

      return Decoded(decoded, input.sublist(length));
    } else {
      // A list over 55 bytes long
      List<dynamic> decoded = <dynamic>[];
      int llength = firstByte - 0xf6;
      int length = safeParseInt(hex.encode(input.sublist(1, llength)), 16);
      int totalLength = llength + length;
      if (totalLength > input.length) {
        throw FormatException(
          'Invalid RLP: total length is larger than the data',
        );
      }

      Uint8List innerRemainder = input.sublist(llength, totalLength);

      if (innerRemainder.length == 0) {
        throw FormatException('Invalid RLP: list has a invalid length');
      }

      while (innerRemainder.length > 0) {
        Decoded d = _decode(innerRemainder);
        decoded.add(d.data);
        innerRemainder = d.remainder;
      }
      return Decoded(
        decoded,
        input.sublist(totalLength),
      );
    }
  }
}

/// A helper class used for decoding RLP data.
class Decoded {
  /// RLP decoded data
  final List<dynamic> data;
  final Uint8List remainder;

  /// Constructor for Decoded class
  const Decoded(this.data, this.remainder);
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:rlp/src/byte_sink.dart';
import 'package:rlp/src/utils.dart';

import 'address.dart';

/// RLP Recursive Length Prefix (Encoder only)
class Rlp {
  /// Performs RLP encoding
  static Uint8List encode(dynamic value) {
    final byteSink = TransactionByteSink();
    _encodeToBuffer(value, byteSink);
    return byteSink.asBytes();
  }

  static void _encodeToBuffer(dynamic value, TransactionByteSink builder) {
    if (value is List) {
      _encodeList(value, builder);
    } else if (value is String) {
      if (isHexString(value)) {
        _encodeString(
          Uint8List.fromList(hex.decode(padToEven(stripHexPrefix(value)))),
          builder,
        );
      } else {
        _encodeString(
          Uint8List.fromList(utf8.encode(value)),
          builder,
        );
      }
    } else if (value is int) {
      _encodeInt(BigInt.from(value), builder);
    } else if (value is BigInt) {
      _encodeInt(value, builder);
    } else if (value is Address) {
      return _encodeString(
        Uint8List.fromList(hex.decode(
          padToEven(stripHexPrefix(value.toString())),
        )),
        builder,
      );
    } else {
      throw Exception('Type not supported for RLP encoding');
    }
  }

  static _encodeInt(BigInt value, TransactionByteSink builder) {
    if (value == BigInt.zero) {
      _encodeString(Uint8List(0), builder);
    } else {
      _encodeString(_unsignedIntToBytes(value), builder);
    }
  }

  static _encodeList(List list, TransactionByteSink builder) {
    final subBuilder = TransactionByteSink();
    for (final item in list) {
      _encodeToBuffer(item, subBuilder);
    }

    final length = subBuilder.length;
    if (length <= 55) {
      builder
        ..addByte(0xc0 + length)
        ..add(subBuilder.asBytes());
      return;
    } else {
      final encodedLength = _unsignedIntToBytes(BigInt.from(length));

      builder
        ..addByte(0xf7 + encodedLength.length)
        ..add(encodedLength)
        ..add(subBuilder.asBytes());
      return;
    }
  }

  static _encodeString(Uint8List string, TransactionByteSink builder) {
    // For a single byte in [0x00, 0x7f], that byte is its own RLP encoding
    if (string.length == 1 && string[0] <= 0x7f) {
      builder.addByte(string[0]);
      return;
    }

    // If a string is between 0 and 55 bytes long, its encoding is 0x80 plus
    // its length, followed by the actual string
    if (string.length <= 55) {
      builder
        ..addByte(0x80 + string.length)
        ..add(string);
      return;
    }

    // More than 55 bytes long, RLP is (0xb7 + length of encoded length), followed
    // by the length, followed by the actual string
    final length = string.length;
    final encodedLength = _unsignedIntToBytes(BigInt.from(length));

    builder
      ..addByte(0xb7 + encodedLength.length)
      ..add(encodedLength)
      ..add(string);
  }

  static Uint8List _unsignedIntToBytes(BigInt number) {
    assert(!number.isNegative);
    return _encodeBigIntAsUnsigned(number);
  }

  /// Encode as Big Endian unsigned byte array.
  static Uint8List _encodeBigIntAsUnsigned(BigInt number) {
    var _byteMask = BigInt.from(0xff);
    if (number == BigInt.zero) {
      return Uint8List.fromList([0]);
    }
    var size = number.bitLength + (number.isNegative ? 8 : 7) >> 3;
    var result = Uint8List(size);
    for (var i = 0; i < size; i++) {
      result[size - i - 1] = (number & _byteMask).toInt();
      number = number >> 8;
    }
    return result;
  }

  /// Decodes the Uint8List
  static List<dynamic> decode(Uint8List input) {
    if (input.length == 0) {
      return <dynamic>[];
    }

    Decoded decoded = _decode(input);

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

import 'dart:typed_data';

import 'package:convert/convert.dart';

/// Ethereum Address
class Address {
  /// Internal string representation of the address (with leading 0x)
  String _address;

  /// Address
  Address(this._address);

  /// Encode the address as a 20 byte Uint8List
  Uint8List toBytes() {
    return Uint8List.fromList(hex.decode(_address.substring(2)))
      ..sublist(0, 20);
  }

  String toString() {
    return this._address;
  }
}

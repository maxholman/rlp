import 'package:rlp/rlp.dart';

main() {
  var encoded = Rlp.encode(["dog", "cat"]);
  print(encoded); // Uint8List [200, 131, 100, 111, 103, 131, 99, 97, 116]
}

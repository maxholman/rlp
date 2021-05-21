import 'package:convert/convert.dart';
import 'package:pointycastle/digests/keccak.dart';

import 'package:rlp/rlp.dart';
import 'package:rlp/src/address.dart';

main() {
  var sender = Address('0xba52c75764d6f594735dc735be7f1830cdf58ddf');
  var nonce = 3515;

  var encoded = Rlp.encode([sender, nonce]);

  var out = KeccakDigest(256).process(encoded);
  var contractAddress = hex.encode(out.sublist(12));

  print(
      'Cryptokitties contract address is 0x$contractAddress'); // 0x06012c8cf97bead5deae237070f9587f8e7a266d
}

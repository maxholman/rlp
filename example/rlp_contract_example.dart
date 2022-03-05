import 'package:convert/convert.dart';
import 'package:pointycastle/digests/keccak.dart';

import 'package:rlp/rlp.dart';
import 'package:rlp/src/address.dart';

main() {
  var sender = Address('0x36928500bc1dcd7af6a2b4008875cc336b927d57');
  var nonce = 6;

  var encoded = Rlp.encode([sender, nonce]);

  var out = KeccakDigest(256).process(encoded);
  var contractAddress = hex.encode(out.sublist(12));

  print(
      'Tether USDT contract address is 0x$contractAddress'); // 0xdac17f958d2ee523a2206206994597c13d831ec7
}

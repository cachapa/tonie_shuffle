import 'dart:convert';
import 'dart:typed_data';

const expiryWindow = Duration(minutes: 15);

class JwtUtils {
  JwtUtils._();

  static bool isValid(String jwt) =>
      expiryDate(jwt).difference(DateTime.now()) > expiryWindow;

  static DateTime expiryDate(String jwt) => DateTime.fromMillisecondsSinceEpoch(
      jsonDecode(utf8.decode(_relaxedBase64Decode(jwt.split('.')[1])))['exp'] *
          1000);

  static Uint8List _relaxedBase64Decode(String encoded) {
    var reminder = encoded.length % 4;
    var normalizedLength = encoded.length + (reminder == 0 ? 0 : 4 - reminder);
    var normalized = encoded.padRight(normalizedLength, '=');
    return base64Decode(normalized);
  }
}


class SteganographyAdapter{

  static String encodeMessage(String visibleText, String hiddenMessage) {
    final hiddenBinary = hiddenMessage.codeUnits.map((c) => c.toRadixString(2).padLeft(8,'0')).join('');
    final zeroWidthEncoded = hiddenBinary.replaceAll('0', '\u200B').replaceAll('1', '\u200C');

      return visibleText + zeroWidthEncoded;
  }

  static String decodeMessage(String encodedText) {
    final zeroWidthEncoded = encodedText.replaceAll(RegExp(r'[^\u200B\u200C]'), '');
    final hiddenBinary = zeroWidthEncoded.replaceAll('\u200B','0').replaceAll('\u200C','1');

    final hiddenMessage = String.fromCharCodes(
      RegExp(r'.{8}').allMatches(hiddenBinary).map((match) => int.parse(match.group(0)!, radix: 2)),
    );

      return hiddenMessage;
  }

}
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import "package:asn1lib/asn1lib.dart";
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

class EncryptionAdapter {
  late AsymmetricKeyPair<RSAPublicKey,RSAPrivateKey> _keys;

  String encrypt(String text)  {
    final eng = RSAEngine()..init(true,PublicKeyParameter<RSAPublicKey>(_keys.publicKey) );

    final processed = eng.process(Uint8List.fromList(text.codeUnits) );

      return String.fromCharCode(processed as int);
  }

  String decrypt(String text) {
    final eng = RSAEngine()..init(false,PrivateKeyParameter<RSAPrivateKey>(_keys.privateKey) );

    final processed = eng.process(Uint8List.fromList(text.codeUnits) );

      return String.fromCharCode(processed as int);
  }

  String encryptPrivateKey() {
    RSAPrivateKey key = _keys.privateKey;
    final version = ASN1Integer(BigInt.from(0) );

    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]) );
    final privateKeySeq = ASN1Sequence();
    final topLevelSeq = ASN1Sequence();

    final modulus = ASN1Integer(key.n!);
    final publicExponent = ASN1Integer(BigInt.parse('65537') );
    final privateExponent = ASN1Integer(key.privateExponent!);
    final p = ASN1Integer(key.p!);
    final q = ASN1Integer(key.q!);
    final dP = key.privateExponent! % (key.p!) - BigInt.from(1);
    final exp1 = ASN1Integer(dP);
    final dQ = key.privateExponent! % (key.q!) - BigInt.from(1);
    final exp2 = ASN1Integer(dQ);
    final iQ = key.q!.modInverse(key.p!);
    final co = ASN1Integer(iQ);

      algorithmSeq.add(algorithmAsn1Obj);
      algorithmSeq.add(paramsAsn1Obj);

      privateKeySeq.add(version);
      privateKeySeq.add(modulus);
      privateKeySeq.add(publicExponent);
      privateKeySeq.add(privateExponent);
      privateKeySeq.add(p);
      privateKeySeq.add(q);
      privateKeySeq.add(exp1);
      privateKeySeq.add(exp2);
      privateKeySeq.add(co);

      final publicKeySeqOctetString = ASN1OctetString(Uint8List.fromList(privateKeySeq.encodedBytes) );

      topLevelSeq.add(version);
      topLevelSeq.add(algorithmSeq);
      topLevelSeq.add(publicKeySeqOctetString);

      return base64.encode(topLevelSeq.encodedBytes);
  }

  String encryptPublicKey() {
    RSAPublicKey key = _keys.publicKey;
    final algorithmSeq = ASN1Sequence();

    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x5, 0x0]),
    );
    final publicKeySeq = ASN1Sequence();
    final topLevelSeq = ASN1Sequence();

      algorithmSeq.add(algorithmAsn1Obj);
      algorithmSeq.add(paramsAsn1Obj);

      publicKeySeq.add(ASN1Integer(key.modulus!));
      publicKeySeq.add(ASN1Integer(key.exponent!));

      final publicKeySeqBitString = ASN1BitString(
        Uint8List.fromList(publicKeySeq.encodedBytes),
      );

      topLevelSeq.add(algorithmSeq);
      topLevelSeq.add(publicKeySeqBitString);

      return base64.encode(topLevelSeq.encodedBytes);
  }

  void decodeKeys((String,String) keys) {
     _keys = AsymmetricKeyPair<RSAPublicKey,RSAPrivateKey>(
         _decodePublicKey(keys.$1),
         _decodePrivateKey(keys.$2)
     );
  }

  RSAPrivateKey _decodePrivateKey(String key) {
    Uint8List decoded =  base64.decode(key);
    var asn1Parser = ASN1Parser(decoded);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final privateKey = topLevelSeq.elements[2];

    asn1Parser = ASN1Parser(privateKey.contentBytes()!);
    final pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    final modulus = pkSeq.elements[1] as ASN1Integer;
    final privateExponent = pkSeq.elements[3] as ASN1Integer;
    final p = pkSeq.elements[4] as ASN1Integer;
    final q = pkSeq.elements[5] as ASN1Integer;

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
      modulus.valueAsBigInteger!,
      privateExponent.valueAsBigInteger!,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );

    return rsaPrivateKey;
  }

  RSAPublicKey _decodePublicKey(String key) {
    Uint8List decoded =  base64.decode(key);
    final asn1Parser = ASN1Parser(decoded);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1];

    final publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes()!);
    ASN1Sequence publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    final modulus = publicKeySeq.elements[0] as ASN1Integer;
    final exponent = publicKeySeq.elements[1] as ASN1Integer;

    RSAPublicKey rsaPublicKey = RSAPublicKey(
      modulus.valueAsBigInteger!,
      exponent.valueAsBigInteger!,
    );

    return rsaPublicKey;

  }

  enc.IV getIvFromHash(String hashValue) {
    var maxSeedValue = (1 << 32) - 1;
    var hashBigInt = BigInt.parse(hashValue,radix: 16);
    var seed = hashBigInt % BigInt.from(maxSeedValue);
    var secureRandom = Random(seed.toInt() );
    var iv = enc.IV.fromLength(16);
    var ivBytes = List<int>.generate( 16, (_) => secureRandom.nextInt(256));

      iv.bytes.setAll(0, Uint8List.fromList(ivBytes));

      return iv;
  }

  void generateKeyPair({int bitLength = 2048}) {
    final keyGen = RSAKeyGenerator();

    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'),bitLength,64),
      _generateSecureRandom(),
    ) );
    final pair = keyGen.generateKeyPair();

    final myPublic = pair.publicKey as RSAPublicKey;
    final myPrivate = pair.privateKey as RSAPrivateKey;

    _keys = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
  }

  SecureRandom _generateSecureRandom() {
    final secureRandom = SecureRandom('Fortuna')..seed(
          KeyParameter(Platform.instance.platformEntropySource().getBytes(32) ) );

    return secureRandom;
  }

}
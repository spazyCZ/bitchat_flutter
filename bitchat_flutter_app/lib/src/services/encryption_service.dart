import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Encryption service for end-to-end encryption using X25519 and AES-GCM
class EncryptionService {
  final X25519 x25519 = X25519();
  final AesGcm aesGcm = AesGcm.with256bits();

  SimpleKeyPair? _privateKey;
  SimplePublicKey? _publicKey;

  /// Generate a new X25519 key pair
  Future<void> generateKeyPair() async {
    _privateKey = await x25519.newKeyPair();
    _publicKey = await _privateKey!.extractPublicKey();
  }

  /// Get the public key bytes
  Future<Uint8List?> getPublicKeyBytes() async {
    if (_publicKey == null) return null;
    return Uint8List.fromList(_publicKey!.bytes);
  }

  /// Compute shared secret with peer's public key
  Future<SecretKey> computeSharedSecret(Uint8List peerPublicKeyBytes) async {
    final peerPublicKey = SimplePublicKey(peerPublicKeyBytes, type: KeyPairType.x25519);
    return await x25519.sharedSecretKey(
      keyPair: _privateKey!,
      remotePublicKey: peerPublicKey,
    );
  }

  /// Encrypt a message with a shared secret
  Future<Uint8List> encrypt(Uint8List message, SecretKey sharedSecret) async {
    final nonce = aesGcm.newNonce();
    final secretBox = await aesGcm.encrypt(
      message,
      secretKey: sharedSecret,
      nonce: nonce,
    );
    return Uint8List.fromList([...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes]);
  }

  /// Decrypt a message with a shared secret
  Future<Uint8List> decrypt(Uint8List encrypted, SecretKey sharedSecret) async {
    final nonce = encrypted.sublist(0, 12);
    final mac = Mac(encrypted.sublist(encrypted.length - 16));
    final cipherText = encrypted.sublist(12, encrypted.length - 16);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final decrypted = await aesGcm.decrypt(secretBox, secretKey: sharedSecret);
    return Uint8List.fromList(decrypted);
  }
}

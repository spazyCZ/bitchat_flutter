# Implementation Gap Analysis

This document compares the features promised in `README.md` with what currently exists in the repository. It is intended as a task list for the SWE Agent to continue development of the Flutter client.

## Features Mentioned in README
- Decentralized Bluetooth mesh networking
- End-to-end encryption (X25519 + AES‑256‑GCM)
- Channel-based chats with optional passwords
- Store & forward for offline peers
- IRC‑style command interface
- Message retention controlled by channel owners
- Universal app (iOS & macOS support)
- Cover traffic and timing obfuscation
- Emergency wipe gesture
- Performance optimizations (LZ4 compression, adaptive battery modes, optimized networking)
- Binary protocol with TTL based routing

## Current Implementation Status
- ✅ **Binary Protocol** – Dart implementation of packet encoding/decoding and TTL logic【F:bitchat_flutter_app/lib/src/services/binary_protocol.dart†L1-L103】【F:bitchat_flutter_app/lib/src/services/bluetooth_mesh_service.dart†L318-L340】
- ✅ **Bluetooth Mesh Basics** – Scanning, connecting and message relay via `BluetoothMeshService` (advertising is still a placeholder)【F:bitchat_flutter_app/lib/src/services/bluetooth_mesh_service.dart†L143-L224】【F:bitchat_flutter_app/lib/src/services/bluetooth_mesh_service.dart†L320-L334】
- ✅ **Encryption Service** – X25519 key exchange and AES‑GCM helpers are implemented but not yet fully integrated for channels or signatures【F:bitchat_flutter_app/lib/src/services/encryption_service.dart†L4-L51】
- ✅ **Command System & UI** – `ChatViewModel` handles commands such as `/join`, `/who`, `/nick`, etc., shown below【F:bitchat_flutter_app/lib/src/services/chat_view_model.dart†L104-L147】. A terminal‑style Flutter UI displays messages.
- ❌ **Full Advertising** – Starting BLE advertising currently prints a placeholder message and requires platform channel work【F:bitchat_flutter_app/lib/src/services/bluetooth_mesh_service.dart†L140-L158】
- ❌ **Store & Forward** – No caching layer for offline message delivery exists.
- ❌ **Channel Password Enforcement** – Passwords can be set but are not used for encryption or membership control【F:bitchat_flutter_app/lib/src/services/bluetooth_mesh_service.dart†L349-L365】
- ❌ **Message Retention** – A basic `PersistentStorageService` exists, but retention policies and channel ownership logic are missing【F:bitchat_flutter_app/lib/src/services/persistent_storage_service.dart†L1-L26】
- ❌ **Compression, Cover Traffic, Battery Optimization, Emergency Wipe** – These optimizations are not present in the codebase.

## Task List for SWE Agent
1. **Implement BLE Advertising**
   - Write platform channel code for Android and iOS to broadcast service/characteristic UUIDs so peers can discover the device without initiating a connection.
2. **Integrate Encryption Fully**
   - Use `EncryptionService` for channel messages and private messages.
   - Add Ed25519 digital signatures to packets.
   - Derive channel keys using Argon2 as described in the README.
3. **Store & Forward Mechanism**
   - Cache messages destined for offline peers and deliver them once the peer reconnects.
   - Respect message TTL and deduplication rules.
4. **Channel Management**
   - Enforce passwords for protected channels.
   - Implement ownership transfer and message retention policies.
5. **Performance & Battery Optimizations**
   - Add LZ4 compression for large payloads.
   - Implement adaptive scanning/advertising intervals based on battery state.
   - Add Bloom filter based duplicate detection and message aggregation.
6. **Cover Traffic & Timing Randomization**
   - Periodically send dummy messages and randomize transmission timing as outlined in the README.
7. **Emergency Wipe**
   - Provide a gesture or command to instantly clear all stored data and keys.
8. **Testing**
   - Fix the unit test paths so they run under `flutter test`.
   - Add new tests for encryption, channel logic and store‑and‑forward.

This list should guide future development so the Flutter implementation matches the capabilities advertised in the project README.

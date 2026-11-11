import 'dart:typed_data';

import 'verification_request.dart';

/// One document picked by the agent, before it is sent to PRIVATE storage.
class VerificationUpload {
  const VerificationUpload({required this.category, required this.fileName, required this.bytes});

  final VerificationCategory category;
  final String fileName;
  final Uint8List bytes;
}

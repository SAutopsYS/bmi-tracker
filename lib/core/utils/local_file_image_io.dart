import 'dart:io';

import 'package:flutter/painting.dart';

/// IO platforms: local filesystem avatars.
bool localFileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

ImageProvider? localFileImage(String path) {
  if (!localFileExists(path)) return null;
  return FileImage(File(path));
}

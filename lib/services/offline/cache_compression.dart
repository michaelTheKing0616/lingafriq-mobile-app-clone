// Cache Compression - Compresses cached data to save storage space
// Uses gzip compression for text-based data

import 'dart:convert';
import 'package:archive/archive.dart';

class CacheCompression {
  /// Compress data using gzip
  static List<int> compress(String data) {
    final bytes = utf8.encode(data);
    return GZipEncoder().encode(bytes) ?? bytes;
  }

  /// Decompress gzip data
  static String decompress(List<int> compressedData) {
    try {
      final decompressed = GZipDecoder().decodeBytes(compressedData);
      return utf8.decode(decompressed);
    } catch (e) {
      // If decompression fails, try to decode as plain text
      return utf8.decode(compressedData);
    }
  }

  /// Compress JSON data
  static List<int> compressJson(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    return compress(jsonString);
  }

  /// Decompress JSON data
  static Map<String, dynamic> decompressJson(List<int> compressedData) {
    final jsonString = decompress(compressedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get compression ratio
  static double getCompressionRatio(List<int> original, List<int> compressed) {
    if (original.isEmpty) return 0.0;
    return (1 - (compressed.length / original.length)) * 100;
  }
}

/// Service wrapper for CacheCompression
class CacheCompressionService {
  static final CacheCompressionService _instance = CacheCompressionService._internal();
  factory CacheCompressionService() => _instance;
  CacheCompressionService._internal();

  Future<void> initialize() async {
    // CacheCompression uses static methods, no initialization needed
  }
}


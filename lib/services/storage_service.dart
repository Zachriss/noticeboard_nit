import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Allowed image extensions
  static const List<String> _allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Allowed document extensions
  static const List<String> _allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
  ];

  // Max image size: 10 MB
  static const int maxImageSize = 10 * 1024 * 1024;

  // Max document size: 20 MB
  static const int maxDocumentSize = 20 * 1024 * 1024;

  /// Validate image file type
  static bool isValidImageType(String extension) {
    return _allowedImageExtensions.contains(extension.toLowerCase());
  }

  /// Validate document file type
  static bool isValidDocumentType(String extension) {
    return _allowedDocumentExtensions.contains(extension.toLowerCase());
  }

  /// Validate image file size
  static bool isValidImageSize(int bytes) {
    return bytes <= maxImageSize;
  }

  /// Validate document file size
  static bool isValidDocumentSize(int bytes) {
    return bytes <= maxDocumentSize;
  }

  /// Get file extension from path
  static String getExtension(String path) {
    return path.split('.').last;
  }

  /// Get file name from path
  static String getFileName(String path) {
    return path.split('/').last;
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    return await file.length();
  }

  /// Upload image to Firebase Storage
  Future<String> uploadImage({
    required String filePath,
    required String noticeId,
    String? fileName,
    List<int>? fileBytes,
  }) async {
    final extension = fileBytes != null
        ? (fileName != null ? getExtension(fileName) : 'jpg')
        : getExtension(filePath);
    final ref = _storage.ref('notices/images/$noticeId.$extension');

    final uploadTask = fileBytes != null
        ? ref.putData(Uint8List.fromList(fileBytes))
        : ref.putFile(File(filePath));

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload document to Firebase Storage
  Future<String> uploadDocument({
    required String filePath,
    required String noticeId,
    String? fileName,
    List<int>? fileBytes,
  }) async {
    final extension = fileBytes != null
        ? (fileName != null ? getExtension(fileName) : 'pdf')
        : getExtension(filePath);
    final ref = _storage.ref('notices/documents/$noticeId.$extension');

    final uploadTask = fileBytes != null
        ? ref.putData(Uint8List.fromList(fileBytes))
        : ref.putFile(File(filePath));

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }

  /// Delete document from Firebase Storage
  Future<void> deleteDocument(String documentUrl) async {
    try {
      final ref = _storage.refFromURL(documentUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  /// Read a picked image file as bytes (cross-platform)
  /// On Web, the file path is a blob URL so we must read via XFile.readAsBytes()
  /// On mobile/desktop, we read via File directly.
  Future<Uint8List?> readImageBytes(XFile xfile) async {
    try {
      return await xfile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Pick document from device
  Future<PlatformFile?> pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, // Get file bytes in case path is null
    );
    return result?.files.first;
  }
}
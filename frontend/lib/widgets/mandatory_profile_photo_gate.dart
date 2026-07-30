import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class MandatoryProfilePhotoGate extends StatefulWidget {
  final String userId;
  final bool required;
  final Widget child;

  const MandatoryProfilePhotoGate({
    super.key,
    required this.userId,
    required this.required,
    required this.child,
  });

  @override
  State<MandatoryProfilePhotoGate> createState() =>
      _MandatoryProfilePhotoGateState();
}

class _MandatoryProfilePhotoGateState extends State<MandatoryProfilePhotoGate> {
  File? _photo;
  bool _uploading = false;
  bool _completed = false;
  String? _error;

  bool get _blocked => widget.required && !_completed;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  Future<void> _upload() async {
    if (_photo == null || _uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final extension = _photo!.path.split('.').last.toLowerCase();
      final subtype = extension == 'png'
          ? 'png'
          : extension == 'webp'
          ? 'webp'
          : 'jpeg';
      final request = http.MultipartRequest('POST', ApiConfig.uri('/profile/photo/'))
        ..fields['user_id'] = widget.userId
        ..files.add(
          await http.MultipartFile.fromPath(
            'profile_photo',
            _photo!.path,
            contentType: MediaType('image', subtype),
          ),
        );
      final response = await http.Response.fromStream(await request.send());
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        if (mounted) setState(() => _completed = true);
      } else {
        throw Exception(data['message'] ?? 'Upload failed');
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_blocked)
          Positioned.fill(
            child: Material(
              color: const Color(0xE6000B18),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Display Picture Required', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Upload your profile photo to continue using HRMS.', textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _uploading ? null : _pick,
                              child: CircleAvatar(
                                radius: 58,
                                backgroundImage: _photo == null ? null : FileImage(_photo!),
                                child: _photo == null ? const Icon(Icons.add_a_photo_rounded, size: 42) : null,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _photo == null || _uploading ? null : _upload,
                                icon: _uploading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.cloud_upload_rounded),
                                label: Text(_uploading ? 'Uploading...' : 'Upload & Continue'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

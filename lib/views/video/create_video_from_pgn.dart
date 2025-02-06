import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class CreateVideoFromPGN extends StatefulWidget {
  const CreateVideoFromPGN({super.key});

  @override
  State<CreateVideoFromPGN> createState() => _CreateVideoFromPGNState();
}

class _CreateVideoFromPGNState extends State<CreateVideoFromPGN> {
  File? _pgnFile;
  String? _fileName;
  final TextEditingController _pgnContentController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _playedAsBlack = false;

  @override
  void dispose() {
    _pgnContentController.dispose();
    super.dispose();
  }

  Future<void> _pickPGNFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pgn'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        setState(() {
          _pgnFile = file;
          _fileName = result.files.single.name;
          _pgnContentController.text = content;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PGN file: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createVideoFromPGN() async {
    if (_pgnContentController.text.isEmpty) {
      setState(() {
        _error = 'Please provide PGN content';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final callable = FirebaseFunctions.instance.httpsCallable('convertPgnToGifHttp');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final result = await callable.call({
        'userId': userId,
        'pgnContent': _pgnContentController.text,
        'fileName': _fileName,
        'flipped': _playedAsBlack,
      });

      if (result.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PGN conversion started successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Conversion failed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error converting PGN: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Create from PGN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Description
              const Text(
                'Create a video by uploading a PGN file or pasting PGN content.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Upload Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pickPGNFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload_file),
                      const SizedBox(width: 8),
                      Text(
                        _pgnFile != null ? 'Change File' : 'Upload PGN File',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Selected: $_fileName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // PGN Content Input
              TextField(
                controller: _pgnContentController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'PGN Content',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Paste PGN content here...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // Color Selection
              Row(
                children: [
                  const Text(
                    'I played as:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('White'),
                    selected: !_playedAsBlack,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _playedAsBlack = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Black'),
                    selected: _playedAsBlack,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _playedAsBlack = true;
                        });
                      }
                    },
                  ),
                ],
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],

              const Spacer(),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createVideoFromPGN,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Video',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/video_types.dart';
import 'video_review_screen.dart';

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

      final callable =
          FirebaseFunctions.instance.httpsCallable('convertPgnToGifHttp');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate a unique ID for the GIF conversion.
      final gifId = const Uuid().v4();

      // Insert initial status into "gif_statuses".
      final gifStatusRef =
          FirebaseFirestore.instance.collection('gif_statuses').doc(gifId);
      await gifStatusRef.set({
        'uuid': gifId,
        'status': 'processing',
      });

      // Call the Cloud Function with the provided PGN content and parameters.
      final result = await callable.call({
        'userId': userId,
        'pgnContent': _pgnContentController.text,
        'fileName': gifId,
        'flipped': _playedAsBlack,
        'uuid': gifId,
      });

      if (result.data['success'] == true) {
        // Capture the NavigatorState before any async gaps.
        if (!mounted) return;
        final navigator = Navigator.of(context);

        // Show a modal dialog that polls the document in "gif_statuses".
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => GifStatusDialog(
            gifStatusRef: gifStatusRef,
            navigator: navigator,
          ),
        );

        // When the conversion is complete, navigate to the VideoReviewScreen
        if (mounted) {
          final firebase_storage.Reference videoRef = firebase_storage
              .FirebaseStorage.instance
              .ref()
              .child('videos/$gifId.mp4');
          // Retrieve the download URL
          final String downloadUrl = await videoRef.getDownloadURL();

          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => VideoReviewScreen(
                videoData: VideoData.fromUrl(downloadUrl, 'videos/$gifId.mp4'),
                initialPgnContent: _pgnContentController.text,
              ),
            ),
          );
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          style: const TextStyle(fontSize: 18, color: Colors.white),
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

                // Add padding to push button to bottom when possible.
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

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
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A modal widget that polls the status of the GIF conversion in real time.
/// It listens to the Firestore document in "gif_statuses" and displays a progress indicator,
/// a success icon when completed, or an error message.
/// Instead of using BuildContext after an async gap, we use a pre-captured NavigatorState.
class GifStatusDialog extends StatefulWidget {
  final DocumentReference gifStatusRef;
  final NavigatorState navigator;
  const GifStatusDialog({
    super.key,
    required this.gifStatusRef,
    required this.navigator,
  });

  @override
  State<GifStatusDialog> createState() => _GifStatusDialogState();
}

class _GifStatusDialogState extends State<GifStatusDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Processing PGN', textAlign: TextAlign.center),
      content: StreamBuilder<DocumentSnapshot>(
        stream: widget.gifStatusRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'An error occurred.',
              textAlign: TextAlign.center,
            );
          }
          if (!snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            );
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'processing';

          if (status == 'converting') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Converting PGN to video...'),
              ],
            );
          } else if (status == 'completed') {
            // Capture the navigator before the async gap.
            final nav = widget.navigator;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              if (nav.canPop()) nav.pop();
            });
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('Video conversion complete!'),
              ],
            );
          } else if (status == 'error') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error converting PGN to video.'),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

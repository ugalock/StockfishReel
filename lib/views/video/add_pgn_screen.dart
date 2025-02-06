import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chess/chess.dart' as chess;
import 'dart:io';
import 'game_details_screen.dart';

class AddPGNScreen extends StatefulWidget {
  final File videoFile;

  const AddPGNScreen({
    super.key,
    required this.videoFile,
  });

  @override
  State<AddPGNScreen> createState() => _AddPGNScreenState();
}

class _AddPGNScreenState extends State<AddPGNScreen> {
  File? _pgnFile;
  String? _pgnContent;
  String? _openingName;
  List<String> _moves = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _pgnContentController = TextEditingController();

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
        _pgnContentController.text = content;
        await _processPGNContent(content);
        setState(() {
          _pgnFile = file;
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

  Future<void> _processPGNContent(String content) async {
    try {
      // Parse PGN content
      final game = chess.Chess();
      game.load_pgn(content);
      
      // Extract moves and convert them to strings
      final moves = game.history.map((move) => move.toString()).toList();
      
      // Try to detect opening (simplified)
      String opening = "Unknown Opening";
      if (moves.isNotEmpty) {
        if (moves[0] == "e4") {
          opening = "King's Pawn Opening";
        } else if (moves[0] == "d4") {
          opening = "Queen's Pawn Opening";
        }
      }

      setState(() {
        _pgnContent = content;
        _openingName = opening;
        _moves = moves;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing PGN content: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _proceedToGameDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameDetailsScreen(
          videoFile: widget.videoFile,
          pgnContent: _pgnContent,
          moves: _moves,
          openingName: _openingName,
        ),
      ),
    );
  }

  void _skipPGN() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameDetailsScreen(
          videoFile: widget.videoFile,
        ),
      ),
    );
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
                      'Add PGN File',
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
                'Upload a PGN file or paste PGN content to show chess moves, highlight openings, and add timestamps for middle/endgame phases.',
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
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _processPGNContent(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              if (_pgnContent != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Opening: ${_openingName ?? "Unknown"}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Moves: ${_moves.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],

              const Spacer(),

              // Next/Skip Buttons
              Column(
                children: [
                  if (_pgnContent != null)
                    ElevatedButton(
                      onPressed: _proceedToGameDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skipPGN,
                    child: const Text(
                      'Skip PGN Upload',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
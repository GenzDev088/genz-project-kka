import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main.dart';
import 'controller.dart';

class ChatPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String sessionKey;
  const ChatPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.sessionKey,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _showScrollToBottom = false;
  bool _uploadingImage = false;

  StreamSubscription? _chatSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
    _startFirebaseChat();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startFirebaseChat() {
    setState(() => _loading = true);
    final fb = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/');
    final chatRef = fb.ref('chats/${widget.deviceId}');

    _chatSub = chatRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          bool isDuplicate = _messages.any((msg) => msg['text'] == data['text'] && (msg['timestamp'] - data['timestamp']).abs() < 5000);
          if (!isDuplicate) {
            setState(() {
              _messages.add(data);
              _loading = false;
            });
            _scrollToBottom();
          }
        } catch (e) {
          debugPrint('Firebase chat parse error: $e');
        }
      }
    });
    

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _messages.isEmpty) {
        setState(() => _loading = false);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final fb = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://mantax-e0919-default-rtdb.asia-southeast1.firebasedatabase.app/');
      final chatRef = fb.ref('chats/${widget.deviceId}').push();
      await chatRef.set({
        'sender': 'admin',
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _inputController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Firebase Send error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _uploadingImage = true);
      try {
        String? uploadedUrl = await HttpService.uploadFile(
          result.files.single.path!,
        );
        if (uploadedUrl != null) {
          await _sendMessage('[IMG]$baseUrl$uploadedUrl');
        }
      } catch (e) {
        debugPrint('Upload image error: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
        }
      } finally {
        if (mounted) setState(() => _uploadingImage = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deviceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Online',
              style: TextStyle(color: Color(0xFF3DDC97), fontSize: 11),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty && !_loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: Color(0xFF7A7A8C),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada percakapan',
                              style: TextStyle(
                                color: Color(0xFF7A7A8C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 20,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isAdmin = msg['sender'] == 'admin';
                          final text = msg['text']?.toString() ?? '';
                          final isImage = text.startsWith('[IMG]');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: isAdmin
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: isAdmin
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isAdmin) ...[
                                      const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Color(0xFF1E1E2E),
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: isImage
                                            ? const EdgeInsets.all(4)
                                            : const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                        decoration: BoxDecoration(
                                          gradient: isAdmin
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF5252),
                                                    Color(0xFFD32F2F),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : const LinearGradient(
                                                  colors: [
                                                    Color(0xFF2C2C3E),
                                                    Color(0xFF1E1E2E),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft: Radius.circular(
                                              isAdmin ? 18 : 4,
                                            ),
                                            bottomRight: Radius.circular(
                                              isAdmin ? 4 : 18,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: isImage
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Image.network(
                                                  text.substring(5),
                                                  width: 220,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null)
                                                          return child;
                                                        return Container(
                                                          width: 220,
                                                          height: 150,
                                                          color: Colors.black12,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder: (c, e, s) =>
                                                      Container(
                                                        width: 220,
                                                        height: 100,
                                                        color: Colors.black26,
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                ),
                                              )
                                            : Text(
                                                text,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.5,
                                                  height: 1.3,
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.done_all_rounded,
                                        size: 14,
                                        color: Color(0xFF3DDC97),
                                      ),
                                    ],
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 4,
                                    left: isAdmin ? 0 : 40,
                                    right: isAdmin ? 22 : 0,
                                  ),
                                  child: Text(
                                    _formatTime(msg['timestamp']),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF12121A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: _uploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Colors.white70,
                                ),
                          onPressed: _uploadingImage ? null : _pickAndSendImage,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: TextField(
                              controller: _inputController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle: TextStyle(color: Color(0xFF7A7A8C)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) =>
                                  _sendMessage(_inputController.text),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendMessage(_inputController.text),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_loading && _messages.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (_showScrollToBottom)
            Positioned(
              right: 20,
              bottom: 100,
              child: FloatingActionButton.small(
                backgroundColor: const Color(0xFF1E1E2E),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white70,
                ),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}

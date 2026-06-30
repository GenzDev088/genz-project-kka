import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'main.dart';

class ChatRoomPage extends StatefulWidget {
  final String username;

  const ChatRoomPage({super.key, required this.username});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = <String>{};
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;

  Timer? _pollTimer;
  Timer? _recordTimer;

  bool _loading = true;
  bool _sendingText = false;
  bool _sendingMedia = false;
  bool _emojiOpen = false;
  bool _showScrollButton = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;

  int _lastTimestamp = 0;
  int _recordSeconds = 0;

  String? _recordPath;
  String? _playingId;
  String? _profileImagePath;
  Map<String, dynamic>? _replyTarget;

  static const Color _bg = Color(0xFF070C14);
  static const Color _primaryCyan = Color(0xFF00B4D8);
  static const Color _accentPurple = Color(0xFF7C4DFF);
  static const Color _surface = Color(0xFF101722);
  static const Color _surfaceAlt = Color(0xFF161F2D);
  static const Color _surfaceSoft = Color(0xFF1A2331);
  static const Color _stroke = Color(0xFF232E3F);
  static const Color _bubbleMine = Color(0xFF1A4D8F);
  static const Color _bubbleMineSoft = Color(0xFF244F85);
  static const Color _bubbleOther = Color(0xFF151D2A);
  static const Color _solid = Color(0xFF89A2C7);
  static const Color _text = Color(0xFFF5F7FB);
  static const Color _muted = Color(0xFF8C9BB1);
  static const Color _danger = Color(0xFFE66A6A);

  static const List<String> _emojiList = [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '😎',
    '🤔',
    '😭',
    '😮',
    '😴',
    '😡',
    '🔥',
    '✨',
    '🎉',
    '❤️',
    '👍',
    '🙏',
    '👏',
    '🤝',
    '🫡',
    '💯',
    '☕',
    '🌙',
    '🎧',
    '📷',
    '🚀',
    '✅',
    '⚡',
    '📌',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    _loadProfileImage();
    _startPolling();
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlayingAudio = false;
        _playingId = null;
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final distance = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
    final nextState = distance > 280;
    if (nextState != _showScrollButton && mounted) {
      setState(() => _showScrollButton = nextState);
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path');
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _emojiOpen) {
      setState(() => _emojiOpen = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final uri = initial || _lastTimestamp == 0
          ? Uri.parse('$baseUrl/chatroom')
          : Uri.parse('$baseUrl/chatroom?since=$_lastTimestamp');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        if (initial && mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final List<dynamic> rawList = jsonDecode(res.body) as List<dynamic>;

      if (initial) {
        _messages.clear();
        _messageIds.clear();
        _lastTimestamp = 0;
      }

      var added = 0;
      for (final raw in rawList) {
        final normalized = _normalizeMessage(raw as Map<String, dynamic>);
        final id = normalized['id'] as String;
        if (_messageIds.contains(id)) continue;
        _messageIds.add(id);
        _messages.add(normalized);
        final time = normalized['time'] as int;
        if (time > _lastTimestamp) {
          _lastTimestamp = time;
        }
        added++;
      }

      _messages.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));

      if (!mounted) return;
      setState(() => _loading = false);
      if (initial || added > 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: !initial),
        );
      }
    } catch (_) {
      if (initial && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> raw) {
    final time = raw['time'] is int
        ? raw['time'] as int
        : int.tryParse('${raw['time']}') ??
              DateTime.now().millisecondsSinceEpoch;
    final from = '${raw['from'] ?? 'Unknown'}';
    final message = '${raw['message'] ?? ''}';
    final type = '${raw['type'] ?? 'text'}';
    final mediaUrl = '${raw['mediaUrl'] ?? ''}';
    final mimeType = '${raw['mimeType'] ?? ''}';
    final fileName = '${raw['fileName'] ?? ''}';
    final duration = raw['duration'] is int
        ? raw['duration'] as int
        : int.tryParse('${raw['duration']}') ?? 0;
    final size = raw['size'] is int
        ? raw['size'] as int
        : int.tryParse('${raw['size']}') ?? 0;
    final fallbackId =
        '${time}_${from}_${type}_${message.hashCode}_${mediaUrl.hashCode}';
    final rawReply = raw['replyTo'];

    return {
      'id': '${raw['id'] ?? fallbackId}',
      'from': from,
      'message': message,
      'type': type,
      'mediaUrl': mediaUrl,
      'mimeType': mimeType,
      'fileName': fileName,
      'duration': duration,
      'size': size,
      'status': '${raw['status'] ?? 'terkirim'}',
      'time': time,
      'replyTo': rawReply is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawReply)
          : rawReply is Map
          ? Map<String, dynamic>.from(rawReply)
          : null,
    };
  }

  Map<String, dynamic> _buildReplyPayload(Map<String, dynamic> message) {
    return {
      'id': message['id'],
      'from': message['from'],
      'type': message['type'],
      'message': message['message'],
      'mediaUrl': message['mediaUrl'],
      'fileName': message['fileName'],
    };
  }

  String _replyPreview(Map<String, dynamic>? reply) {
    if (reply == null) return '';
    final type = '${reply['type'] ?? 'text'}';
    final text = '${reply['message'] ?? ''}'.trim();
    if (type == 'image') {
      return text.isNotEmpty ? 'Foto • $text' : 'Foto';
    }
    if (type == 'audio') {
      return text.isNotEmpty ? 'Voice note • $text' : 'Voice note';
    }
    return text;
  }

  String _composerHint() {
    if (_replyTarget != null) {
      return 'Tulis balasan untuk ${_replyTarget!['from']}...';
    }
    return 'Kirim Pesan....';
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sendingText || _sendingMedia || _isRecording) return;

    final optimistic = {
      'id': 'local_${DateTime.now().microsecondsSinceEpoch}',
      'from': widget.username,
      'message': text,
      'type': 'text',
      'mediaUrl': '',
      'mimeType': '',
      'fileName': '',
      'duration': 0,
      'size': 0,
      'status': 'mengirim',
      'time': DateTime.now().millisecondsSinceEpoch,
      'replyTo': _replyTarget != null
          ? _buildReplyPayload(_replyTarget!)
          : null,
    };

    final replyPayload = optimistic['replyTo'];
    _msgCtrl.clear();
    setState(() {
      _sendingText = true;
      _emojiOpen = false;
      _messages.add(optimistic);
      _replyTarget = null;
    });
    _scrollToBottom();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/chatroom'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'from': widget.username,
              'message': text,
              'replyTo': replyPayload,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final idx = _messages.indexWhere((m) => m['id'] == optimistic['id']);
      if (idx < 0) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final normalized = _normalizeMessage(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        _messages[idx] = normalized;
        _messageIds.add(normalized['id'] as String);
        final sentTime = normalized['time'] as int;
        _lastTimestamp = _lastTimestamp < sentTime ? sentTime : _lastTimestamp;
      } else {
        _messages[idx]['status'] = 'gagal';
      }
    } catch (_) {
      final idx = _messages.indexWhere((m) => m['id'] == optimistic['id']);
      if (idx >= 0) {
        _messages[idx]['status'] = 'gagal';
      }
    } finally {
      if (mounted) {
        setState(() => _sendingText = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_sendingMedia || _isRecording) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    final caption = _msgCtrl.text.trim();
    await _sendMedia(File(path), message: caption);
    if (caption.isNotEmpty && mounted) {
      _msgCtrl.clear();
    }
  }

  Future<void> _sendMedia(
    File file, {
    String message = '',
    int duration = 0,
  }) async {
    if (_sendingMedia) return;

    final replyPayload = _replyTarget != null
        ? _buildReplyPayload(_replyTarget!)
        : null;

    setState(() {
      _sendingMedia = true;
      _emojiOpen = false;
      _replyTarget = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/chatroom/media'),
      );
      request.fields['from'] = widget.username;
      request.fields['message'] = message;
      request.fields['duration'] = '$duration';
      if (replyPayload != null) {
        request.fields['replyTo'] = jsonEncode(replyPayload);
      }
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send().timeout(const Duration(minutes: 2));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final parsed = jsonDecode(body) as Map<String, dynamic>;
        final normalized = _normalizeMessage(
          Map<String, dynamic>.from(parsed['data'] as Map),
        );
        if (!_messageIds.contains(normalized['id'])) {
          _messageIds.add(normalized['id'] as String);
          _messages.add(normalized);
          final sentTime = normalized['time'] as int;
          _lastTimestamp = _lastTimestamp < sentTime
              ? sentTime
              : _lastTimestamp;
        }
        if (mounted) {
          setState(() {});
          _scrollToBottom();
        }
      } else {
        String errorMessage = 'Gagal kirim media';
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final serverMessage = '${parsed['message'] ?? parsed['error'] ?? ''}'
              .trim();
          if (serverMessage.isNotEmpty) {
            errorMessage = serverMessage;
          }
        } catch (_) {}
        if (mounted) _showSnack(errorMessage);
      }
    } catch (e) {
      if (mounted) _showSnack('Upload media gagal: $e');
    } finally {
      if (mounted) {
        setState(() => _sendingMedia = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_sendingText || _sendingMedia) return;

    if (_isRecording) {
      await _stopAndSendRecording();
      return;
    }

    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (mounted) _showSnack('Izin mikrofon belum diberikan');
      return;
    }

    final path =
        '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordPath = path;
      _recordSeconds = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
      });

      if (mounted) {
        setState(() {
          _isRecording = true;
          _emojiOpen = false;
        });
      }
    } catch (_) {
      if (mounted) _showSnack('Gagal mulai rekam suara');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      final sendPath = path ?? _recordPath;
      final seconds = _recordSeconds;

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordSeconds = 0;
        });
      }

      if (sendPath == null) return;
      final file = File(sendPath);
      if (await file.exists()) {
        await _sendMedia(file, duration: seconds);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordSeconds = 0;
        });
        _showSnack('Gagal kirim voice note');
      }
    }
  }

  Future<void> _toggleAudio(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final url = item['mediaUrl'] as String;
    if (url.isEmpty) return;

    try {
      if (_playingId == id && _isPlayingAudio) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _playingId = null;
          _isPlayingAudio = false;
        });
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      if (!mounted) return;
      setState(() {
        _playingId = id;
        _isPlayingAudio = true;
      });
    } catch (_) {
      if (mounted) _showSnack('Audio tidak bisa diputar');
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position.maxScrollExtent + 120;
    if (animated) {
      _scrollCtrl.animateTo(
        position,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollCtrl.jumpTo(position);
    }
  }

  void _highlightMessage(String id) {
    setState(() => _highlightedMessageId = id);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _highlightedMessageId == id) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _toggleEmojiPanel() {
    FocusScope.of(context).unfocus();
    setState(() => _emojiOpen = !_emojiOpen);
  }

  void _insertEmoji(String emoji) {
    final value = _msgCtrl.value;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : value.text.length;
    final end = selection.end >= 0 ? selection.end : value.text.length;
    final next = value.text.replaceRange(start, end, emoji);
    _msgCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() {});
  }

  void _setReplyTarget(Map<String, dynamic> message) {
    setState(() {
      _replyTarget = message;
      _emojiOpen = false;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  Widget _buildMessageText(String text) {
    final RegExp mentionRegex = RegExp(r'(@[^\s]+)');
    final Iterable<Match> matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: _text,
          fontSize: 14.5,
          height: 1.42,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    int currentIndex = 0;
    final List<TextSpan> spans = [];

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: Color(0xFF6AB0FF),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _text,
          fontSize: 14.5,
          height: 1.42,
          fontWeight: FontWeight.w500,
        ),
        children: spans,
      ),
    );
  }

  void _showMessageActions(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _stroke,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              _sheetAction(Icons.reply_rounded, 'Balas pesan', () {
                Navigator.pop(context);
                _setReplyTarget(item);
              }),
              _sheetAction(Icons.copy_all_rounded, 'Salin teks', () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(text: '${item['message'] ?? ''}'),
                );
                _showSnack('Pesan disalin');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _text, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _timeText(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _dateText(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    final diff = today.difference(current).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _durationText(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceAlt,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101A).withValues(alpha: 0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: _stroke.withValues(alpha: 0.6), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _roundButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF266ED9), Color(0xFF1A4D8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF266ED9).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: _profileImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _profileImagePath!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ).animate().shimmer(duration: 1500.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Nongkrong',
                  style: TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Halo, ${widget.username}!',
                  style: const TextStyle(
                    color: _primaryCyan,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _roundButton(Icons.info_outline_rounded, _openInfoPage),
        ],
      ),
    );
  }

  void _openInfoPage() {
    final participants = _messages.map((e) => e['from']).toSet().length;
    final latestSender = _messages.isEmpty
        ? widget.username
        : '${_messages.last['from']}';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ChatroomInfoPage(
          totalMessages: _messages.length,
          participants: participants,
          latestSender: latestSender,
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2A3A), Color(0xFF141C26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _stroke.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _text, size: 18),
      ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _surfaceSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _stroke.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _solid,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String sender, bool isMe) {
    final bool useImage = isMe && _profileImagePath != null;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [const Color(0xFF387BDB), const Color(0xFF1A4D8F)]
              : [const Color(0xFF2C3E50), const Color(0xFF1A2331)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      alignment: Alignment.center,
      child: useImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: _profileImagePath!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Text(
                  sender.isEmpty ? '?' : sender[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                errorWidget: (context, url, error) => Text(
                  sender.isEmpty ? '?' : sender[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Text(
              sender.isEmpty ? '?' : sender[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReplyChip(Map<String, dynamic> reply, bool isMe) {
    return GestureDetector(
      onTap: () {
        final targetId = reply['id'] as String?;
        if (targetId != null && _messageKeys.containsKey(targetId)) {
          final context = _messageKeys[targetId]?.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
            _highlightMessage(targetId);
          }
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF224878) : _surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: isMe ? Colors.white70 : _solid, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${reply['from'] ?? 'Unknown'}',
              style: const TextStyle(
                color: _text,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _replyPreview(reply),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> item) {
    final mediaUrl = item['mediaUrl'] as String;
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Gambar tidak dapat dimuat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          mediaUrl,
          width: 230,
          height: 230,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 230,
            height: 230,
            color: _surfaceSoft,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_rounded,
              color: _muted,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(Map<String, dynamic> item, bool isMe) {
    final id = item['id'] as String;
    final playing = _playingId == id && _isPlayingAudio;
    final duration = item['duration'] as int;
    return InkWell(
      onTap: () => _toggleAudio(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF214777) : _surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isMe ? const Color(0xFF30609A) : _stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2E5D93) : const Color(0xFF202B3A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: _text,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    16,
                    (index) => Container(
                      width: 3,
                      height: 7 + (index % 4) * 4,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: index.isEven ? 0.85 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  duration > 0 ? _durationText(duration) : 'Voice note',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> item, bool isMe, bool showAvatar) {
    final type = item['type'] as String;
    final reply = item['replyTo'] as Map<String, dynamic>?;
    final sender = item['from'] as String;
    final status = item['status'] as String;

    final isHighlighted = item['id'] == _highlightedMessageId;
    Color bubbleColor = isMe ? _bubbleMine : _bubbleOther;
    if (isHighlighted) {
      bubbleColor = _solid.withValues(alpha: 0.4);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 70 : 14,
        showAvatar ? 10 : 4,
        isMe ? 14 : 70,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            SizedBox(
              width: 42,
              child: showAvatar
                  ? _buildAvatar(sender, isMe)
                  : const SizedBox.shrink(),
            ),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Text(
                      sender,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Dismissible(
                  key: ValueKey('reply_${item['id']}'),
                  direction: isMe
                      ? DismissDirection.endToStart
                      : DismissDirection.startToEnd,
                  confirmDismiss: (_) async {
                    _setReplyTarget(item);
                    return false;
                  },
                  background: _buildReplySwipeBackground(isMe),
                  secondaryBackground: _buildReplySwipeBackground(isMe),
                  child: GestureDetector(
                    onDoubleTap: () => _setReplyTarget(item),
                    onLongPress: () => _showMessageActions(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        type == 'image' ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isMe && !isHighlighted
                            ? const LinearGradient(
                                colors: [Color(0xFF1D5AAB), Color(0xFF0F356B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : (!isMe && !isHighlighted)
                            ? const LinearGradient(
                                colors: [Color(0xFF1C2636), Color(0xFF121822)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isHighlighted ? bubbleColor : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: Radius.circular(isMe ? 22 : 8),
                          bottomRight: Radius.circular(isMe ? 8 : 22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isMe
                              ? const Color(0xFF3B72C4).withValues(alpha: 0.4)
                              : _stroke.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reply != null) _buildReplyChip(reply, isMe),
                          if (type == 'image') _buildImage(item),
                          if (type == 'audio') _buildAudioPlayer(item, isMe),
                          if ((item['message'] as String)
                              .trim()
                              .isNotEmpty) ...[
                            if (type != 'text') const SizedBox(height: 10),
                            _buildMessageText(item['message'] as String),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _timeText(item['time'] as int),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  status == 'gagal'
                                      ? Icons.error_outline_rounded
                                      : status == 'mengirim'
                                      ? Icons.schedule_rounded
                                      : Icons.done_all_rounded,
                                  size: 14,
                                  color: status == 'gagal'
                                      ? _danger
                                      : status == 'mengirim'
                                      ? _muted
                                      : const Color(0xFFD6E5FA),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe)
            SizedBox(
              width: 42,
              child: showAvatar
                  ? _buildAvatar(sender, isMe)
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildReplySwipeBackground(bool isMe) {
    return Container(
      margin: EdgeInsets.fromLTRB(isMe ? 90 : 54, 8, isMe ? 54 : 90, 2),
      padding: EdgeInsets.only(left: isMe ? 0 : 18, right: isMe ? 18 : 0),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _stroke),
      ),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isMe
            ? const [
                Text(
                  'Balas',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.reply_rounded, color: _solid, size: 18),
              ]
            : const [
                Icon(Icons.reply_rounded, color: _solid, size: 18),
                SizedBox(width: 8),
                Text(
                  'Balas',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _text));
    }

    if (_messages.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surfaceSoft.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _stroke.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 44, color: _muted),
              SizedBox(height: 14),
              Text(
                'Belum ada percakapan',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mulai kirim pesan, foto, voice note, dan gunakan reply untuk membalas chat tertentu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _text,
      backgroundColor: _surface,
      onRefresh: () => _loadMessages(initial: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
        itemCount: _messages.length,
        itemBuilder: (_, index) {
          final item = _messages[index];
          final isMe = item['from'] == widget.username;
          final currentDate = _dateText(item['time'] as int);
          final previousDate = index == 0
              ? ''
              : _dateText(_messages[index - 1]['time'] as int);
          final showDate = index == 0 || currentDate != previousDate;
          final previousSender = index == 0
              ? ''
              : '${_messages[index - 1]['from']}';
          final showAvatar = index == 0 || previousSender != '${item['from']}';

          final msgId = item['id'] as String;
          if (!_messageKeys.containsKey(msgId)) {
            _messageKeys[msgId] = GlobalKey();
          }

          return Column(
            key: _messageKeys[msgId],
            children: [
              if (showDate) _buildDateDivider(currentDate),
              _buildBubble(item, isMe, showAvatar),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReplyComposer() {
    if (_replyTarget == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: _solid,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balas ${_replyTarget!['from']}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyPreview(_replyTarget),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyTarget = null),
            icon: const Icon(Icons.close_rounded, color: _muted, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    if (!_isRecording) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: _danger, size: 18),
          const SizedBox(width: 10),
          Text(
            'Merekam ${_durationText(_recordSeconds)}',
            style: const TextStyle(
              color: _text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _toggleRecording,
            child: const Text(
              'Kirim',
              style: TextStyle(
                color: _text,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPanel() {
    if (!_emojiOpen) return const SizedBox.shrink();
    return Container(
      height: 210,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _stroke.withValues(alpha: 0.6)),
      ),
      child: GridView.builder(
        itemCount: _emojiList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (_, index) {
          final emoji = _emojiList[index];
          return InkWell(
            onTap: () => _insertEmoji(emoji),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 23)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    final hasText = _msgCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1724).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _stroke.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyComposer(),
          _buildRecordingBar(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _iconAction(Icons.sentiment_satisfied_rounded, _toggleEmojiPanel),
              const SizedBox(width: 10),
              _iconAction(Icons.image_outlined, _pickAndSendImage),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _stroke.withValues(alpha: 0.6)),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    onTap: () {
                      if (_emojiOpen) {
                        setState(() => _emojiOpen = false);
                      }
                    },
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                      hintText: _composerHint(),
                      hintStyle: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: hasText
                    ? _sendButton(
                        key: const ValueKey('send'),
                        icon: Icons.send_rounded,
                        onTap: _sendText,
                      )
                    : _sendButton(
                        key: const ValueKey('mic'),
                        icon: _isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        onTap: _toggleRecording,
                      ),
              ),
            ],
          ),
          if (_sendingText || _sendingMedia) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _text,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _sendingMedia ? 'Mengunggah media...' : 'Mengirim pesan...',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _surfaceSoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _stroke.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, color: _solid, size: 22),
      ),
    );
  }

  Widget _sendButton({
    required Key key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF266ED9), Color(0xFF1A4D8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF266ED9).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF4585E6).withValues(alpha: 0.5),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0D1C2E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _bg,
        body: Stack(
          children: [

            Positioned.fill(
              child: CustomPaint(
                painter: _ChatBgPainter(_primaryCyan.withValues(alpha: 0.05)),
              ),
            ),


            Positioned(
              top: -100,
              right: -50,
              child:
                  Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _primaryCyan.withValues(alpha: 0.03),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 2.seconds)
                      .scale(duration: 3.seconds),
            ),

            Positioned(
              bottom: 100,
              left: -100,
              child:
                  Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentPurple.withValues(alpha: 0.02),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 3.seconds)
                      .scale(duration: 4.seconds),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMessageList()),
                  _buildEmojiPanel(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: _buildComposer(),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _showScrollButton
            ? FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: _surfaceAlt,
                foregroundColor: _text,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ).animate().fadeIn().scale()
            : null,
      ),
    );
  }
}

class _ChatBgPainter extends CustomPainter {
  final Color color;
  _ChatBgPainter(this.color);

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;


    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(ui.Offset(i, 0), ui.Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(ui.Offset(0, i), ui.Offset(size.width, i), paint);
    }


    final hexPaint = Paint()
      ..color = color.withValues(alpha: 0.02)
      ..style = ui.PaintingStyle.stroke;

    final random = math.Random(42);
    for (int i = 0; i < 8; i++) {
      double cx = random.nextDouble() * size.width;
      double cy = random.nextDouble() * size.height;
      double r = 40 + random.nextDouble() * 80;

      final path = ui.Path();
      for (int j = 0; j < 6; j++) {
        double angle = (math.pi / 3) * j;
        double x = cx + r * math.cos(angle);
        double y = cy + r * math.sin(angle);
        if (j == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, hexPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ChatroomInfoPage extends StatelessWidget {
  final int totalMessages;
  final int participants;
  final String latestSender;

  const _ChatroomInfoPage({
    required this.totalMessages,
    required this.participants,
    required this.latestSender,
  });

  static const Color _bg = Color(0xFF070C14);
  static const Color _surface = Color(0xFF101722);
  static const Color _surfaceSoft = Color(0xFF1A2331);
  static const Color _stroke = Color(0xFF232E3F);
  static const Color _solid = Color(0xFF89A2C7);
  static const Color _text = Color(0xFFF5F7FB);
  static const Color _muted = Color(0xFF8C9BB1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _stroke),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _text,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Info Chatroom',
                          style: TextStyle(
                            color: _text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Detail ruang obrolan',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _stroke),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room Nongkrong',
                          style: TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ruang obrolan realtime untuk kirim pesan teks, gambar, voice note, dan reply pesan secara cepat.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoTile(
                    Icons.chat_bubble_rounded,
                    'Total pesan',
                    '$totalMessages pesan tersimpan',
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.people_alt_rounded,
                    'Member aktif',
                    '$participants pengguna terdeteksi di percakapan',
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.reply_rounded,
                    'Reply pesan',
                    'Bisa dengan geser bubble atau double tap',
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.bolt_rounded,
                    'Aktivitas terakhir',
                    latestSender,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF141D2A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _stroke),
            ),
            child: Icon(icon, color: _solid, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

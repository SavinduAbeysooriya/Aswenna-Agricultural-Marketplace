import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class ChatMessage {
  final String role;
  final String message;
  final DateTime dateAndTime;
  final String? imagePath;

  const ChatMessage({
    required this.role,
    required this.message,
    required this.dateAndTime,
    this.imagePath,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  String? _sessionId;
  bool _isWaiting = false;
  String? _selectedImagePath;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isWaiting = true);
    final res = await ApiService.createChatSession();
    if (!mounted) return;
    if (res['success'] == true) {
      _sessionId = res['session_id'];
      await _loadMessages();
    } else {
      setState(() => _isWaiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to initialize session.')),
      );
    }
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    final res = await ApiService.getChatSessionMessages(_sessionId!);
    if (!mounted) return;
    if (res['success'] == true) {
      final List<dynamic> msgs = res['messages'] ?? [];
      setState(() {
        _messages.clear();
        for (final m in msgs) {
          _messages.add(ChatMessage(
            role: m['role'] ?? 'user',
            message: m['message'] ?? '',
            dateAndTime: DateTime.now(),
            imagePath: m['image_path'] != null && m['image_path'].toString().isNotEmpty
                ? '${ApiService.appUrl}/storage/${m['image_path']}'
                : null,
          ));
        }
        _isWaiting = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isWaiting = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sessionId == null) return;

    // Instantly append user's message in UI
    final userMsg = ChatMessage(
      role: 'user',
      message: text,
      dateAndTime: DateTime.now(),
      imagePath: _selectedImagePath,
    );

    final imageToSend = _selectedImagePath;

    setState(() {
      _messages.add(userMsg);
      _selectedImagePath = null;
      _isWaiting = true;
    });

    _inputController.clear();
    _scrollToBottom();

    // Call API
    final res = await ApiService.sendChatMessage(_sessionId!, text, imagePath: imageToSend);
    if (!mounted) return;

    if (res['success'] == true) {
      final List<dynamic> msgs = res['messages'] ?? [];
      setState(() {
        _messages.clear();
        for (final m in msgs) {
          _messages.add(ChatMessage(
            role: m['role'] ?? 'user',
            message: m['message'] ?? '',
            dateAndTime: DateTime.now(),
            imagePath: m['image_path'] != null && m['image_path'].toString().isNotEmpty
                ? '${ApiService.appUrl}/storage/${m['image_path']}'
                : null,
          ));
        }
        _isWaiting = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isWaiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to communicate with AI agent.')),
      );
    }
  }

  Future<void> _startNewSession() async {
    setState(() {
      _messages.clear();
      _isWaiting = true;
      _sessionId = null;
    });
    final res = await ApiService.createChatSession();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _sessionId = res['session_id'];
      });
      await _loadMessages();
    } else {
      setState(() => _isWaiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to initialize session.')),
      );
    }
  }

  Future<void> _switchSession(String sessionId) async {
    setState(() {
      _messages.clear();
      _isWaiting = true;
      _sessionId = sessionId;
    });
    await _loadMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.lightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.deepLeafGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Aswenna AI Assistant',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history_rounded, color: AppTheme.darkGreen),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: _ChatSessionsDrawer(
        currentSessionId: _sessionId,
        onSessionSelected: _switchSession,
        onStartNewChat: _startNewSession,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isWaiting
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + (_isWaiting ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.lightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.deepLeafGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aswenna AI Assistant',
              style: TextStyle(
                color: AppTheme.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about rice cultivation, soil quality, market prices, or pest control.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('How to improve rice cultivation?'),
                _buildSuggestionChip('How to improve soil quality?'),
                _buildSuggestionChip('What are current market prices?'),
                _buildSuggestionChip('Organic paddy bug control'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _inputController.text = label;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.deepLeafGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.lightMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppTheme.deepLeafGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.deepLeafGreen : AppTheme.pureWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    if (!isUser)
                      BoxShadow(
                        color: AppTheme.deepLeafGreen.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.imagePath != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: message.imagePath!.startsWith('http')
                              ? Image.network(
                                  message.imagePath!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(message.imagePath!),
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ],
                    _buildFormattedMessage(message.message, isUser),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.dateAndTime),
                      style: TextStyle(
                        color: isUser ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.lightMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.deepLeafGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepLeafGreen.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const SizedBox(width: 40, child: _TypingDots()),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImagePath != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_selectedImagePath!),
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Image attached',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
                    onPressed: () => setState(() => _selectedImagePath = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.deepLeafGreen, size: 28),
                onPressed: _pickImage,
                tooltip: 'Attach Image',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask the Aswenna AI...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.softGray,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.deepLeafGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineRichText(String line, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(r'(\*\*.*?\*\*|##.*?##|\*.*?\*|_.*?_)');
    final matches = regExp.allMatches(line);
    
    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: line.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }
      
      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchText.startsWith('##') && matchText.endsWith('##')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchText.startsWith('_') && matchText.endsWith('_')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildFormattedMessage(String text, bool isUser) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];
    
    final baseColor = isUser ? Colors.white : const Color(0xFF0F172A);
    final bulletColor = isUser ? Colors.white.withOpacity(0.7) : AppTheme.deepLeafGreen;
    
    final baseTextStyle = TextStyle(
      color: baseColor,
      fontSize: 14,
      height: 1.4,
    );
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      if (trimmed.startsWith('### ')) {
        final headerText = line.replaceFirst('### ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: _buildLineRichText(
            headerText,
            TextStyle(
              color: isUser ? Colors.white : AppTheme.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        final headerText = line.replaceFirst('## ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: _buildLineRichText(
            headerText,
            TextStyle(
              color: isUser ? Colors.white : AppTheme.darkGreen,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ));
      } else if (trimmed.startsWith('# ')) {
        final headerText = line.replaceFirst('# ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: _buildLineRichText(
            headerText,
            TextStyle(
              color: isUser ? Colors.white : AppTheme.darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        final itemText = line.replaceFirst('- ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: bulletColor, fontSize: 14, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildLineRichText(itemText, baseTextStyle),
              ),
            ],
          ),
        ));
      } else if (trimmed.startsWith('* ')) {
        final itemText = line.replaceFirst('* ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: bulletColor, fontSize: 14, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildLineRichText(itemText, baseTextStyle),
              ),
            ],
          ),
        ));
      } else {
        if (line.isNotEmpty || i < lines.length - 1) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildLineRichText(line, baseTextStyle),
          ));
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.deepLeafGreen
                    .withValues(alpha: 0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatSessionsDrawer extends StatefulWidget {
  final String? currentSessionId;
  final Function(String sessionId) onSessionSelected;
  final VoidCallback onStartNewChat;

  const _ChatSessionsDrawer({
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onStartNewChat,
  });

  @override
  State<_ChatSessionsDrawer> createState() => _ChatSessionsDrawerState();
}

class _ChatSessionsDrawerState extends State<_ChatSessionsDrawer> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await ApiService.getChatSessions();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _sessions = res['sessions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load sessions';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.softGray,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.pureWhite,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.deepLeafGreen),
                  const SizedBox(width: 8),
                  const Text(
                    'Chat Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Start New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onStartNewChat();
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Start New Chat',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepLeafGreen,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sessions List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _sessions.isEmpty
                          ? const Center(
                              child: Text(
                                'No previous conversations.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                final isSelected = session['session_id'] == widget.currentSessionId;
                                final title = session['title'] ?? 'Conversation';
                                final timeStr = session['updated_at'] != null
                                    ? _formatSessionTime(session['updated_at'])
                                    : '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onSessionSelected(session['session_id']);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.lightMint
                                            : AppTheme.pureWhite,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.deepLeafGreen
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_rounded,
                                            color: isSelected
                                                ? AppTheme.deepLeafGreen
                                                : const Color(0xFF94A3B8),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 13,
                                                    color: isSelected
                                                        ? AppTheme.darkGreen
                                                        : const Color(0xFF334155),
                                                  ),
                                                ),
                                                if (timeStr.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    timeStr,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionTime(String rawTime) {
    try {
      final parsed = DateTime.parse(rawTime).toLocal();
      final now = DateTime.now();
      if (parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
        return 'Today at ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return '';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class ChatMessage {
  final String farmerQuiz;
  final String? botAnswer;
  final DateTime dateAndTime;
  final int order;
  final String? imagePath;

  const ChatMessage({
    required this.farmerQuiz,
    this.botAnswer,
    required this.dateAndTime,
    required this.order,
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
  bool _isEnded = false;
  bool _isWaiting = false;
  bool _isSubmitting = false;
  int? _customerRating;
  final TextEditingController _feedbackController = TextEditingController();
  String? _chatTitle;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isEnded) return;

    final order = _messages.length + 1;
    _chatTitle ??= text.length > 40 ? '${text.substring(0, 40)}...' : text;

    final message = ChatMessage(
      farmerQuiz: text,
      botAnswer: null, // TODO: AI model will populate this
      dateAndTime: DateTime.now(),
      order: order,
    );

    setState(() {
      _messages.add(message);
      _isWaiting = true;
    });

    _inputController.clear();
    _scrollToBottom();

    // TODO: Replace with actual AI model call — set botAnswer when integrated
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isWaiting = false);
      _scrollToBottom();
    });
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

  void _endSession() {
    if (_messages.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isEnded = true);
  }

  Future<void> _submitAndClose() async {
    setState(() => _isSubmitting = true);

    // Build messages payload from all conversation messages
    final payload = _messages.map((m) => {
      'farmer_quiz': m.farmerQuiz,
      'bot_answer': m.botAnswer,
      'order': m.order,
      'date_and_time': m.dateAndTime.toIso8601String(),
    }).toList();

    await ApiService.saveChatSession(
      messages: payload,
      chatTitle: _chatTitle,
      customerRating: _customerRating,
      customerFeedback: _feedbackController.text,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aswenna AI Agent'),
            if (_chatTitle != null)
              Text(
                _chatTitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (!_isEnded && _messages.isNotEmpty)
            TextButton(
              onPressed: _endSession,
              child: const Text(
                'End Chat',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                      return _buildMessagePair(_messages[index]);
                    },
                  ),
          ),
          if (_isEnded) _buildFeedbackPanel() else _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
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
              'Aswenna AI Agent',
              style: TextStyle(
                color: AppTheme.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about farming, crops, market prices, or agricultural advice.',
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
                _buildSuggestionChip('Best crops for this season?'),
                _buildSuggestionChip('How to improve soil quality?'),
                _buildSuggestionChip('Current market prices'),
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

  Widget _buildMessagePair(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Farmer question — right aligned
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.deepLeafGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.farmerQuiz,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.dateAndTime),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Bot answer — left aligned
          Align(
            alignment: Alignment.centerLeft,
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
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepLeafGreen.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // AI response space — shows unavailable when botAnswer is null
                    child: message.botAnswer != null
                        ? Text(
                            message.botAnswer!,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'Unavailable right now our AI agent',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask the AI agent...',
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
    );
  }

  Widget _buildFeedbackPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rate this conversation',
            style: TextStyle(
              color: AppTheme.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _customerRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    _customerRating != null && star <= _customerRating!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.accentGold,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Leave feedback (optional)',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppTheme.softGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit & Close'),
            ),
          ),
        ],
      ),
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

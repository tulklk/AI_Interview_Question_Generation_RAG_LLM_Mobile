import 'package:flutter/material.dart';
import '../../domain/models/generated_question.dart';
import '../models/chat_message.dart';
import '../models/question_suggestion.dart';
import '../services/ask_ai_service.dart';

export '../models/question_suggestion.dart';

const _primary = Color(0xFF7C3AED);

// ── Public show function ──────────────────────────────────────────────────────

Future<void> showAskAiSheet(
  BuildContext context, {
  required GeneratedQuestion question,
  required String jobId,
  void Function(QuestionSuggestion)? onApplySuggestion,
  bool readOnly = false,
}) {
  return showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    useRootNavigator:   true,
    builder: (ctx) => AskAIPanel(
      question:          question,
      jobId:             jobId,
      readOnly:          readOnly,
      onApplySuggestion: onApplySuggestion != null
          ? (s) {
              Navigator.of(ctx).pop();
              onApplySuggestion(s);
            }
          : (_) {},
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

const _kExamples = [
  'Làm câu hỏi khó hơn',
  'Thêm câu hỏi follow-up',
  'Viết lại dạng behavioral',
  'Giải thích rationale',
  'Thêm câu trả lời mẫu',
];

// ── Public widget ─────────────────────────────────────────────────────────────

class AskAIPanel extends StatefulWidget {
  final GeneratedQuestion question;
  final String jobId;
  final void Function(QuestionSuggestion) onApplySuggestion;
  final VoidCallback onClose;
  final bool readOnly;

  const AskAIPanel({
    super.key,
    required this.question,
    required this.jobId,
    required this.onApplySuggestion,
    required this.onClose,
    this.readOnly = false,
  });

  @override
  State<AskAIPanel> createState() => _AskAIPanelState();
}

class _AskAIPanelState extends State<AskAIPanel> {
  final _scrollCtrl = ScrollController();
  final _textCtrl   = TextEditingController();

  List<ChatMessage> _messages       = [];
  bool              _historyLoading  = true;
  String            _draft           = '';
  bool              _loading         = false;
  String?           _error;
  String?           _lastAiMessageId;

  bool get _questionIdValid =>
      !widget.question.id.startsWith('q-') &&
      !widget.question.id.startsWith('stub-') &&
      !widget.question.id.startsWith('manual-') &&
      !widget.question.id.startsWith('local-');

  @override
  void initState() {
    super.initState();
    if (!_questionIdValid) {
      setState(() => _historyLoading = false);
      return;
    }
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await AskAiService.getChatHistory(
          widget.jobId, widget.question.id);
      if (!mounted) return;
      setState(() {
        _messages       = history;
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _draft.trim();
    if (text.isEmpty || _loading || !_questionIdValid) return;

    setState(() { _error = null; _draft = ''; });
    _textCtrl.clear();

    final hrMsg = ChatMessage(
      id:      'hr-${DateTime.now().millisecondsSinceEpoch}',
      role:    'hr',
      content: text,
    );
    setState(() { _messages.add(hrMsg); _loading = true; });
    _scrollToBottom();

    try {
      final result = await AskAiService.sendMessage(
          widget.jobId, widget.question.id, text);
      if (!mounted) return;
      final msgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.add(ChatMessage(
          id:         msgId,
          role:       'ai',
          content:    result.reply,
          suggestion: result.suggestion,
        ));
        _lastAiMessageId = msgId;
        _loading         = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1629) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: _primary, width: 2)),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          _buildHeader(isDark),
          Expanded(child: _buildBody(isDark)),
          if (!widget.readOnly) _buildInput(isDark),
          if (widget.readOnly)
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width:  36,
        height: 4,
        decoration: BoxDecoration(
          color:        isDark
              ? const Color(0xFF374151)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E2640) : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width:  24,
            height: 24,
            decoration: BoxDecoration(
              color:        _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 12, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.readOnly ? 'Lịch sử AI Chat' : 'Ask AI',
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.readOnly
                      ? 'Xem lại cuộc hội thoại AI về câu hỏi này.'
                      : 'Hỏi về câu hỏi này — AI có đầy đủ ngữ cảnh về JD, kế hoạch và câu hỏi này.',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap:        widget.onClose,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(bool isDark) {
    if (_historyLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 13, height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: _primary),
            ),
            const SizedBox(width: 8),
            Text('Đang tải lịch sử...',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    if (_messages.isEmpty && !_loading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount:  _messages.length +
          (_loading ? 1 : 0) +
          (_error != null ? 1 : 0),
      itemBuilder: (_, i) {
        if (i < _messages.length) {
          return _buildChatBubble(_messages[i], isDark);
        }
        if (_loading && i == _messages.length) {
          return _buildThinkingBubble(isDark);
        }
        return _buildErrorRow();
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing:    6,
        runSpacing: 6,
        children: _kExamples
            .map((p) => GestureDetector(
                  onTap: () => setState(() {
                    _draft = p;
                    _textCtrl.text = p;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border:       Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Chat bubble ───────────────────────────────────────────────────────────

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    final isAI     = msg.role == 'ai';
    final isLastAI = isAI && msg.id == _lastAiMessageId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            _buildAvatar(isAI: true, isDark: isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bubbleColor(isAI, isDark),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(12),
                      topRight:    const Radius.circular(12),
                      bottomLeft:  Radius.circular(isAI ? 4 : 12),
                      bottomRight: Radius.circular(isAI ? 12 : 4),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                        fontSize: 12,
                        height:   1.6,
                        color:    _bubbleTextColor(isAI, isDark)),
                  ),
                ),
                if (isLastAI && msg.suggestion != null) ...[
                  const SizedBox(height: 8),
                  _buildSuggestionCard(msg.suggestion!),
                ],
              ],
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            _buildAvatar(isAI: false, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Color _bubbleColor(bool isAI, bool isDark) {
    if (isAI) {
      return isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
    }
    return isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
  }

  Color _bubbleTextColor(bool isAI, bool isDark) {
    if (isAI) {
      return isDark
          ? const Color(0xFFC7D2FE)
          : const Color(0xFF3730A3);
    }
    return isDark ? const Color(0xFFE5E7EB) : Colors.grey.shade800;
  }

  Widget _buildAvatar({required bool isAI, required bool isDark}) {
    return Container(
      width:  20,
      height: 20,
      decoration: BoxDecoration(
        color: isAI
            ? _primary.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF374151) : Colors.grey.shade200),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isAI ? 'AI' : 'HR',
          style: TextStyle(
              fontSize:   8,
              fontWeight: FontWeight.bold,
              color:      isAI ? _primary : Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isAI: true, isDark: isDark),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1B4B)
                  : const Color(0xFFEEF2FF),
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(12),
                topRight:    Radius.circular(12),
                bottomLeft:  Radius.circular(4),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 11, height: 11,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _primary),
                ),
                const SizedBox(width: 6),
                Text('Đang suy nghĩ...',
                    style: TextStyle(
                        fontSize: 11,
                        color:    isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF4338CA))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 12, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã xảy ra lỗi. Vui lòng thử lại.',
                style: TextStyle(
                    fontSize: 11, color: Colors.red.shade600)),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    size: 11, color: Colors.red.shade600),
                const SizedBox(width: 2),
                Text('Thử lại',
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      Colors.red.shade600,
                        decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestion card ───────────────────────────────────────────────────────

  Widget _buildSuggestionCard(QuestionSuggestion s) {
    return Container(
      decoration: BoxDecoration(
        color:        _primary.withValues(alpha: 0.05),
        border:       Border.all(color: _primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: _primary.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 11, color: _primary),
                const SizedBox(width: 6),
                const Text(
                  'CÂU HỎI ĐỀ XUẤT',
                  style: TextStyle(
                      fontSize:      10,
                      fontWeight:    FontWeight.w600,
                      color:         _primary,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.question,
                    style: const TextStyle(fontSize: 12, height: 1.6)),
                if (s.questionType != null || s.difficulty != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (s.questionType != null)
                        _buildBadge(s.questionType!, 'type'),
                      if (s.difficulty != null)
                        _buildBadge(s.difficulty!, 'difficulty'),
                    ],
                  ),
                ],
                if (s.rationale != null) ...[
                  const SizedBox(height: 8),
                  Text(s.rationale!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onApplySuggestion(s),
                icon:  const Icon(Icons.check_circle_outline_rounded,
                    size: 12),
                label: const Text('Áp dụng câu hỏi này',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String type) {
    final Color bg, fg, border;
    if (type == 'difficulty') {
      switch (label.toLowerCase()) {
        case 'hard':
          bg     = const Color(0xFFFFF1F2);
          fg     = const Color(0xFFBE123C);
          border = const Color(0xFFFFE4E6);
        case 'medium':
          bg     = const Color(0xFFFFFBEB);
          fg     = const Color(0xFFB45309);
          border = const Color(0xFFFEF3C7);
        default:
          bg     = const Color(0xFFECFDF5);
          fg     = const Color(0xFF065F46);
          border = const Color(0xFFD1FAE5);
      }
    } else {
      bg     = const Color(0xFFEEF2FF);
      fg     = const Color(0xFF4338CA);
      border = const Color(0xFFE0E7FF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: fg)),
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────

  Widget _buildInput(bool isDark) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2640) : Colors.grey.shade100,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_questionIdValid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 12, color: Colors.amber.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Câu hỏi này chưa được lưu lên server. Hãy lưu bản nháp trước khi hỏi AI.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLines:   4,
                  minLines:   2,
                  enabled:    !_loading && !_historyLoading && _questionIdValid,
                  style:      const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText:  'vd: Làm khó hơn, thêm câu behavioral, giải thích rationale...',
                    hintStyle: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide:   BorderSide(color: _primary, width: 1.5),
                    ), // ignore: prefer_const_constructors
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _draft = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width:  36,
                height: 36,
                child:  ElevatedButton(
                  onPressed: _draft.trim().isEmpty || _loading || !_questionIdValid
                      ? null
                      : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:        _primary,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.4),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 13, height: 13,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white))
                      : const Icon(Icons.send_rounded,
                          size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

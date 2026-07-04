import 'dart:async';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../hr_generate/data/generation_api.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _maxBytes = 20 * 1024 * 1024; // 20 MB

// ── Models ────────────────────────────────────────────────────────────────────

enum DocStatus { pending, ingesting, processing, ready, failed }

class KnowledgeDocument {
  final String id;
  final String fileName;
  final int? fileSize;
  final DocStatus status;
  final DateTime? createdAt;
  final String? errorMessage;

  const KnowledgeDocument({
    required this.id,
    required this.fileName,
    this.fileSize,
    required this.status,
    this.createdAt,
    this.errorMessage,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> j) {
    final raw    = j['status'] as String? ?? 'pending';
    final status = _parseStatus(raw);
    return KnowledgeDocument(
      id:           j['id']?.toString() ?? '',
      fileName:     j['originalFileName'] ?? j['fileName'] ?? 'Document',
      fileSize:     j['fileSize'] as int?,
      status:       status,
      createdAt:    j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      errorMessage: j['errorMessage'] as String?,
    );
  }

  KnowledgeDocument copyWith({DocStatus? status, String? errorMessage}) =>
      KnowledgeDocument(
        id:           id,
        fileName:     fileName,
        fileSize:     fileSize,
        status:       status ?? this.status,
        createdAt:    createdAt,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isInProgress =>
      status == DocStatus.pending ||
      status == DocStatus.ingesting ||
      status == DocStatus.processing;

  static DocStatus _parseStatus(String s) {
    switch (s.toUpperCase()) {
      case 'READY':
      case 'COMPLETED':    return DocStatus.ready;
      case 'FAILED':       return DocStatus.failed;
      case 'INGESTING':    return DocStatus.ingesting;
      case 'PROCESSING':   return DocStatus.processing;
      default:             return DocStatus.pending;
    }
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class KnowledgeState {
  final List<KnowledgeDocument> docs;
  final bool isLoading;
  final bool uploading;
  final String? error;
  final String searchQuery;

  const KnowledgeState({
    this.docs         = const [],
    this.isLoading    = true,
    this.uploading    = false,
    this.error,
    this.searchQuery  = '',
  });

  KnowledgeState copyWith({
    List<KnowledgeDocument>? docs,
    bool? isLoading,
    bool? uploading,
    String? error,
    String? searchQuery,
  }) =>
      KnowledgeState(
        docs:        docs        ?? this.docs,
        isLoading:   isLoading   ?? this.isLoading,
        uploading:   uploading   ?? this.uploading,
        error:       error,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  List<KnowledgeDocument> get filtered {
    if (searchQuery.isEmpty) return docs;
    final q = searchQuery.toLowerCase();
    return docs.where((d) => d.fileName.toLowerCase().contains(q)).toList();
  }

  int get readyCount     => docs.where((d) => d.status == DocStatus.ready).length;
  int get processingCount => docs.where((d) => d.isInProgress).length;
  int get failedCount    => docs.where((d) => d.status == DocStatus.failed).length;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class KnowledgeNotifier extends StateNotifier<KnowledgeState> {
  KnowledgeNotifier() : super(const KnowledgeState()) {
    _init();
  }

  Timer? _pollTimer;

  Future<void> _init() async {
    await load();
    _startPoll();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio  = buildGenerationDio();
      final resp = await dio.get('/api/hr/knowledge-documents');
      final list = _unwrap(resp.data) as List? ?? [];
      final docs = list
          .map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(docs: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: _friendlyError(e));
    }
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!state.docs.any((d) => d.isInProgress)) return;
      try {
        final dio  = buildGenerationDio();
        final resp = await dio.get('/api/hr/knowledge-documents');
        final list = _unwrap(resp.data) as List? ?? [];
        final updated = list
            .map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(docs: updated);
      } catch (_) {}
    });
  }

  Future<void> uploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type:          FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if ((file.size ?? 0) > _maxBytes) {
        state = state.copyWith(error: '${file.name} exceeds 20 MB limit');
        continue;
      }
      await _uploadFile(file);
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final path = file.path;
      if (path == null) return;
      final dio  = buildGenerationDio();
      final form = FormData.fromMap({
        'File': await MultipartFile.fromFile(path, filename: file.name),
      });
      await dio.post('/api/hr/knowledge-documents', data: form);
      await load();
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    } finally {
      state = state.copyWith(uploading: false);
    }
  }

  Future<void> deleteDoc(String id) async {
    try {
      final dio = buildGenerationDio();
      await dio.delete('/api/hr/knowledge-documents/$id');
      state = state.copyWith(
          docs: state.docs.where((d) => d.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  Future<void> reingest(String id) async {
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/knowledge-documents/$id/reingest');
      state = state.copyWith(
        docs: state.docs.map((d) {
          if (d.id != id) return d;
          return d.copyWith(status: DocStatus.ingesting);
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void clearError()        => state = state.copyWith(error: null);

  static dynamic _unwrap(dynamic data) {
    if (data is Map) {
      final inner = data['data'] ?? data['result'] ?? data['documents'];
      if (inner is List) return inner;
    }
    if (data is List) return data;
    return null;
  }

  static String _friendlyError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      return 'Network error: ${e.message}';
    }
    return e.toString();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final knowledgeProvider =
    StateNotifierProvider.autoDispose<KnowledgeNotifier, KnowledgeState>(
        (_) => KnowledgeNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(knowledgeProvider.notifier).setSearch(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<KnowledgeState>(knowledgeProvider, (prev, next) {
      final err = next.error;
      if (err == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      ref.read(knowledgeProvider.notifier).clearError();
    });

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final kState  = ref.watch(knowledgeProvider);
    final notifier = ref.read(knowledgeProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.load,
      color:     const Color(0xFF6C47FF),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats row ────────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                        label: context.l10n.ready,
                        count: kState.readyCount,
                        color: const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _StatChip(
                        label: context.l10n.processing,
                        count: kState.processingCount,
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _StatChip(
                        label: context.l10n.failedStatus,
                        count: kState.failedCount,
                        color: const Color(0xFFEF4444)),
                    const Spacer(),
                    if (kState.uploading)
                      const SizedBox(
                        width:  18,
                        height: 18,
                        child:  CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6C47FF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Search ────────────────────────────────────────────────
                _SearchField(
                  controller: _searchCtrl,
                  isDark:     isDark,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 14),

                // ── Upload zone ───────────────────────────────────────────
                _UploadZone(
                  isDark:    isDark,
                  uploading: kState.uploading,
                  onTap:     () => notifier.uploadFiles(),
                ),
                const SizedBox(height: 16),

                // ── Doc list ──────────────────────────────────────────────
                if (kState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child:   CircularProgressIndicator(
                          color: Color(0xFF6C47FF)),
                    ),
                  )
                else if (kState.filtered.isEmpty)
                  _EmptyState(isDark: isDark)
                else
                  ...kState.filtered.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:   _DocCard(
                          doc:    doc,
                          isDark: isDark,
                          onDelete: () =>
                              _confirmDelete(context, doc, notifier),
                          onReingest: () => notifier.reingest(doc.id),
                        ),
                      )),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    KnowledgeDocument doc,
    KnowledgeNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteConfirmTitle),
        content: Text(ctx.l10n.deleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ctx.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) await notifier.deleteDoc(doc.id);
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('$count $label',
                style: TextStyle(
                    color:      color,
                    fontSize:   11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller:   controller,
        onChanged:    onChanged,
        style:        TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14),
        decoration: InputDecoration(
          hintText:         context.l10n.searchDocs,
          hintStyle:        const TextStyle(color: Color(0xFF6B7280)),
          prefixIcon:       const Icon(Icons.search_rounded,
              color: Color(0xFF6B7280), size: 20),
          filled:           true,
          fillColor:        isDark
              ? const Color(0xFF111827)
              : const Color(0xFFF9FAFB),
          border:           OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   const BorderSide(color: Color(0xFF2D3562)),
          ),
          enabledBorder:    OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide(
                color: isDark
                    ? const Color(0xFF2D3562)
                    : const Color(0xFFE5E7EB)),
          ),
          focusedBorder:    OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   const BorderSide(color: Color(0xFF6C47FF)),
          ),
          contentPadding:   const EdgeInsets.symmetric(
              vertical: 12, horizontal: 14),
        ),
      );
}

class _UploadZone extends StatelessWidget {
  final bool isDark;
  final bool uploading;
  final VoidCallback onTap;

  const _UploadZone({
    required this.isDark,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration:   const Duration(milliseconds: 200),
          padding:    const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:        isDark
                ? const Color(0xFF111827)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.35),
              width: 1.5,
              // ignore: deprecated_member_use
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (uploading)
                const SizedBox(
                  width:  36, height: 36,
                  child:  CircularProgressIndicator(
                      color: Color(0xFF6C47FF), strokeWidth: 3),
                )
              else ...[
                Icon(Icons.cloud_upload_rounded,
                    color: const Color(0xFF6C47FF), size: 36),
                const SizedBox(height: 8),
                Text(context.l10n.uploadFile,
                    style: const TextStyle(
                        color:      Color(0xFF6C47FF),
                        fontSize:   14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(context.l10n.dropFilesHint,
                    style: const TextStyle(
                        color:    Color(0xFF6B7280),
                        fontSize: 11)),
              ],
            ],
          ),
        ),
      );
}

class _DocCard extends StatelessWidget {
  final KnowledgeDocument doc;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onReingest;

  const _DocCard({
    required this.doc,
    required this.isDark,
    required this.onDelete,
    required this.onReingest,
  });

  String get _ext {
    final parts = doc.fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  Color get _statusColor {
    switch (doc.status) {
      case DocStatus.ready:    return const Color(0xFF10B981);
      case DocStatus.failed:   return const Color(0xFFEF4444);
      default:                 return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(BuildContext context) {
    final l = context.l10n;
    switch (doc.status) {
      case DocStatus.ready:      return l.ready;
      case DocStatus.failed:     return l.failedStatus;
      case DocStatus.ingesting:  return '${l.ingestingStatus}…';
      case DocStatus.processing: return '${l.processing}…';
      case DocStatus.pending:    return '${l.pendingStatus}…';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File icon
            Container(
              width:  42,
              height: 42,
              decoration: BoxDecoration(
                color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _ext.length > 4 ? _ext.substring(0, 4) : _ext,
                  style: const TextStyle(
                      color:      Color(0xFF6C47FF),
                      fontSize:   10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    style: TextStyle(
                        color:      isDark ? Colors.white : const Color(0xFF111827),
                        fontSize:   13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status badge
                      _StatusBadge(
                          label: _statusLabel(context),
                          color: _statusColor,
                          pulsing: doc.isInProgress),
                      if (doc.fileSize != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatBytes(doc.fileSize!),
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  if (doc.status == DocStatus.failed &&
                      doc.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      doc.errorMessage!,
                      style: const TextStyle(
                          color:    Color(0xFFEF4444),
                          fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon:    Icon(Icons.more_vert_rounded,
                  color: const Color(0xFF6B7280), size: 20),
              onSelected: (v) {
                if (v == 'delete')   onDelete();
                if (v == 'reingest') onReingest();
              },
              itemBuilder: (ctx) => [
                if (doc.status == DocStatus.failed)
                  PopupMenuItem(
                    value: 'reingest',
                    child: Row(children: [
                      const Icon(Icons.refresh_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(ctx.l10n.reingest),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Text(ctx.l10n.delete,
                        style: const TextStyle(color: Color(0xFFEF4444))),
                  ]),
                ),
              ],
            ),
          ],
        ),
      );

  String _formatBytes(int bytes) {
    if (bytes < 1024)             return '$bytes B';
    if (bytes < 1024 * 1024)      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatusBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.pulsing,
  });

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusBadge old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulsing && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border:       Border.all(color: widget.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
            color:      widget.color,
            fontSize:   10,
            fontWeight: FontWeight.w600),
      ),
    );

    if (!widget.pulsing) return badge;
    return AnimatedBuilder(
      animation: _ctrl,
      builder:   (_, child) => Opacity(
        opacity: 0.6 + 0.4 * _ctrl.value,
        child:   child,
      ),
      child: badge,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded,
                  size:  56,
                  color: isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFD1D5DB)),
              const SizedBox(height: 12),
              Text(
                context.l10n.noDocuments,
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.noDocumentsHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

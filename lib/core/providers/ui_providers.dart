import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Navigation bar visibility ─────────────────────────────────────────────────

/// Set to `false` right before opening a full-height modal bottom sheet so
/// the glass nav bar slides down and out of sight.  Reset to `true` in the
/// sheet's `whenComplete` callback to bring it back.
///
/// All shells watch this provider and animate their nav bars accordingly.
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

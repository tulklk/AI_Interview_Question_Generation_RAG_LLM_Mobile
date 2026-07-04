import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../mock/mock_data.dart';
import '../services/auth_events.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

// ─── Auth ──────────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final AuthErrorType? errorType;
  final bool showWelcome;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.errorType,
    this.showWelcome = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    AuthErrorType? errorType,
    bool? showWelcome,
    bool clearError = false,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        errorType: clearError ? null : (errorType ?? this.errorType),
        showWelcome: showWelcome ?? this.showWelcome,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    AuthEvents.onSessionExpired = _forceLogout;
    _tryRestoreSession();
  }

  void _forceLogout() {
    if (mounted) state = const AuthState();
  }

  @override
  void dispose() {
    AuthEvents.onSessionExpired = null;
    super.dispose();
  }

  // Restore session from SharedPreferences on app start
  Future<void> _tryRestoreSession() async {
    final session = await StorageService.getSavedSession();
    if (session == null || !mounted) return;
    final role = _roleFromString(session['userRole'] ?? '');
    state = AuthState(
      user: UserModel(
        id: session['userId']!,
        name: session['userName']!,
        email: session['userEmail']!,
        role: role,
      ),
    );
  }

  // ── Email / password ──────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await AuthService.loginWithEmail(email, password);
      await StorageService.saveSession(
        accessToken:  result.accessToken,
        refreshToken: result.refreshToken,
        userId:       result.user.id,
        userRole:     result.user.role.name,
        userName:     result.user.name,
        userEmail:    result.user.email,
      );
      if (mounted) state = AuthState(user: result.user, showWelcome: true);
    } on AuthException catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
          errorType: e.type,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Có lỗi xảy ra. Vui lòng thử lại sau.',
          errorType: AuthErrorType.serverError,
        );
      }
    }
  }

  // ── Google OAuth ──────────────────────────────────────────────────────

  Future<void> loginWithGoogle(String idToken, {GoogleProfileData? profile}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await AuthService.loginWithGoogle(idToken, profile: profile);
      await StorageService.saveSession(
        accessToken:  result.accessToken,
        refreshToken: result.refreshToken,
        userId:       result.user.id,
        userRole:     result.user.role.name,
        userName:     result.user.name,
        userEmail:    result.user.email,
      );
      if (mounted) state = AuthState(user: result.user, showWelcome: true);
    } on AuthException catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
          errorType: e.type,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Đăng nhập Google thất bại. Vui lòng thử lại.',
          errorType: AuthErrorType.serverError,
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  void setError(String message, [AuthErrorType type = AuthErrorType.serverError]) {
    state = state.copyWith(
      isLoading: false,
      error: message,
      errorType: type,
    );
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void consumeWelcome() {
    if (state.showWelcome) state = state.copyWith(showWelcome: false);
  }

  Future<void> logout() async {
    await AuthService.logout();          // AC-02: vô hiệu hóa token phía server
    await StorageService.clearSession(); // AC-03: xóa token + session phía client
    if (mounted) state = const AuthState(); // AC-07: đồng bộ trạng thái UI
  }

  static UserRole _roleFromString(String s) {
    switch (s) {
      case 'admin':
        return UserRole.admin;
      case 'hrManager':
        return UserRole.hrManager;
      default:
        return UserRole.candidate;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

// ─── Jobs ──────────────────────────────────────────────────────────────────

final jobsProvider = Provider<List<JobModel>>((ref) => MockData.jobs);

final activeJobsProvider = Provider<List<JobModel>>(
  (ref) => ref.watch(jobsProvider).where((j) => j.status == JobStatus.active).toList(),
);

final jobFilterProvider = StateProvider<JobStatus?>((ref) => null);

final filteredJobsProvider = Provider<List<JobModel>>((ref) {
  final filter = ref.watch(jobFilterProvider);
  final jobs = ref.watch(jobsProvider);
  if (filter == null) return jobs;
  return jobs.where((j) => j.status == filter).toList();
});

// ─── Candidates ────────────────────────────────────────────────────────────

final candidatesProvider = Provider<List<CandidateModel>>((ref) => MockData.candidates);

final candidateStageProvider = StateProvider<CandidateStage?>((ref) => null);

final filteredCandidatesProvider = Provider<List<CandidateModel>>((ref) {
  final stage = ref.watch(candidateStageProvider);
  final candidates = ref.watch(candidatesProvider);
  if (stage == null) return candidates;
  return candidates.where((c) => c.stage == stage).toList();
});

// ─── Interviews ────────────────────────────────────────────────────────────

final interviewsProvider = Provider<List<InterviewModel>>((ref) => MockData.interviews);

final upcomingInterviewsProvider = Provider<List<InterviewModel>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(interviewsProvider)
      .where((i) => i.scheduledAt.isAfter(now) && i.status == InterviewStatus.scheduled)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

// ─── Questions ─────────────────────────────────────────────────────────────

final questionsProvider = Provider<List<QuestionModel>>((ref) => MockData.questions);
final practiceQuestionsProvider = Provider<List<QuestionModel>>((ref) => MockData.practiceQuestions);

// ─── Applications ──────────────────────────────────────────────────────────

final applicationsProvider = Provider<List<ApplicationModel>>((ref) => MockData.applications);

// ─── Practice ──────────────────────────────────────────────────────────────

class PracticeState {
  final int currentIndex;
  final List<QuestionModel> questions;
  final Map<int, String> answers;
  final bool isComplete;

  PracticeState({
    this.currentIndex = 0,
    this.questions = const [],
    this.answers = const {},
    this.isComplete = false,
  });

  PracticeState copyWith({
    int? currentIndex,
    List<QuestionModel>? questions,
    Map<int, String>? answers,
    bool? isComplete,
  }) =>
      PracticeState(
        currentIndex: currentIndex ?? this.currentIndex,
        questions: questions ?? this.questions,
        answers: answers ?? this.answers,
        isComplete: isComplete ?? this.isComplete,
      );

  double get progress =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  PracticeNotifier() : super(PracticeState());

  void startPractice(List<QuestionModel> questions) {
    state = PracticeState(questions: questions);
  }

  void submitAnswer(String answer) {
    final newAnswers = Map<int, String>.from(state.answers);
    newAnswers[state.currentIndex] = answer;
    if (state.currentIndex >= state.questions.length - 1) {
      state = state.copyWith(answers: newAnswers, isComplete: true);
    } else {
      state = state.copyWith(
        answers: newAnswers,
        currentIndex: state.currentIndex + 1,
      );
    }
  }

  void reset() => state = PracticeState();
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>(
  (_) => PracticeNotifier(),
);

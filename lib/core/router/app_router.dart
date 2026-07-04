import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/app_providers.dart';
import '../../models/user_model.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/shell/hr_app_shell.dart';
import '../../features/dashboard/hr_dashboard_screen.dart' as dash;
import '../../features/hr/screens/jobs_screen.dart';
import '../../features/hr/screens/create_job_screen.dart';
import '../../features/hr_generate/presentation/screens/generate_screen.dart';
import '../../features/hr/screens/candidates_screen.dart';
import '../../features/hr/screens/candidate_detail_screen.dart';
import '../../features/hr/screens/interviews_screen.dart';
import '../../features/hr/screens/hr_profile_screen.dart';
import '../../features/knowledge/screens/knowledge_screen.dart';
import '../../features/history/screens/history_list_screen.dart';
import '../../features/history/screens/history_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/candidate/screens/candidate_shell.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/candidate/screens/candidate_jobs_screen.dart';
import '../../features/candidate/screens/job_detail_screen.dart';
import '../../features/candidate/screens/practice_screen.dart';
import '../../features/candidate/screens/practice_question_screen.dart';
import '../../features/candidate/screens/applications_screen.dart';
import '../../features/candidate/screens/candidate_profile_screen.dart';
import '../../features/jobseeker/shell/jobseeker_shell.dart';
import '../../features/jobseeker/screens/dashboard/jobseeker_dashboard_screen.dart';
import '../../features/jobseeker/screens/marketplace/marketplace_screen.dart';
import '../../features/jobseeker/screens/set_detail/set_detail_screen.dart';
import '../../features/jobseeker/screens/practice/practice_session_screen.dart';
import '../../features/jobseeker/screens/feedback/feedback_screen.dart';
import '../../features/jobseeker/screens/history/jobseeker_history_screen.dart';
import '../../features/jobseeker/screens/profile/jobseeker_profile_screen.dart';
import '../../features/jobseeker/screens/settings/jobseeker_settings_screen.dart';

final _rootKey           = GlobalKey<NavigatorState>();
// HR tab branch keys — one per bottom-nav slot
final _hrDashKey         = GlobalKey<NavigatorState>(debugLabel: 'hr_dash');
final _hrHistKey         = GlobalKey<NavigatorState>(debugLabel: 'hr_hist');
final _hrKnowKey         = GlobalKey<NavigatorState>(debugLabel: 'hr_know');
final _hrProfKey         = GlobalKey<NavigatorState>(debugLabel: 'hr_prof');
final _candidateShellKey = GlobalKey<NavigatorState>();
final _jobseekerShellKey = GlobalKey<NavigatorState>();

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
    case UserRole.hrManager:
      return '/hr/dashboard';
    case UserRole.candidate:
      return '/jobseeker/dashboard';
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey:      _rootKey,
    initialLocation:   '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth       = ref.read(authProvider);
      final isLoggedIn = auth.user != null;
      final loc        = state.matchedLocation;

      final isOnAuth = loc.startsWith('/splash') ||
          loc.startsWith('/onboarding') ||
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/forgot-password') ||
          loc.startsWith('/reset-password') ||
          loc.startsWith('/verify-email');

      if (!isLoggedIn && !isOnAuth) return '/login';

      if (isLoggedIn &&
          (loc.startsWith('/login') || loc.startsWith('/register'))) {
        return _homeForRole(auth.user!.role);
      }

      // Redirect legacy root /hr to /hr/dashboard
      if (loc == '/hr') return '/hr/dashboard';

      // Legacy alias used by older generate flow
      if (loc == '/hr/questions') return '/hr/history';

      return null;
    },
    routes: [
      GoRoute(path: '/splash',          builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding',      builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',        builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => EmailVerificationScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // ── AI Generator / Generate — full-screen outside shell ───────────────
      GoRoute(
        path:               '/hr/generate',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => GenerateScreen(
          key: ValueKey(state.uri.toString()),
          resumeJobId: state.uri.queryParameters['jobId'],
        ),
      ),
      // Legacy alias
      GoRoute(
        path:               '/hr/ai-generator',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => GenerateScreen(
          key: ValueKey(state.uri.toString()),
          resumeJobId: state.uri.queryParameters['jobId'],
        ),
      ),
      GoRoute(
        path:               '/hr/ai-generator/plan/:jobId',
        parentNavigatorKey: _rootKey,
        redirect: (_, state) =>
            '/hr/generate?jobId=${Uri.encodeComponent(state.pathParameters['jobId']!)}',
      ),
      GoRoute(
        path:               '/hr/ai-generator/questions/:jobId',
        parentNavigatorKey: _rootKey,
        redirect: (_, state) =>
            '/hr/generate?jobId=${Uri.encodeComponent(state.pathParameters['jobId']!)}',
      ),

      // ── History detail — full-screen outside shell ────────────────────────
      GoRoute(
        path:               '/hr/history/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            HistoryDetailScreen(sessionId: state.pathParameters['id']!),
      ),

      // ── HR Shell (StatefulShellRoute keeps each tab alive) ───────────────
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => HRAppShell(
          currentLocation: state.matchedLocation,
          navigationShell: shell,
        ),
        branches: [
          // ── Branch 0: Dashboard (+ legacy HR routes) ──────────────────────
          StatefulShellBranch(
            navigatorKey: _hrDashKey,
            routes: [
              GoRoute(
                path:    '/hr/dashboard',
                builder: (_, __) => const dash.HRDashboardScreen(),
              ),
              GoRoute(
                path:    '/hr/jobs',
                builder: (_, __) => const JobsScreen(),
                routes: [
                  GoRoute(
                    path:               'create',
                    parentNavigatorKey: _rootKey,
                    builder:            (_, __) => const CreateJobScreen(),
                  ),
                ],
              ),
              GoRoute(
                path:    '/hr/candidates',
                builder: (_, __) => const CandidatesScreen(),
                routes: [
                  GoRoute(
                    path:               ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => CandidateDetailScreen(
                        candidateId: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path:    '/hr/interviews',
                builder: (_, __) => const InterviewsScreen(),
              ),
            ],
          ),

          // ── Branch 1: History ─────────────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _hrHistKey,
            routes: [
              GoRoute(
                path:    '/hr/history',
                builder: (_, __) => const HistoryListScreen(),
              ),
            ],
          ),

          // ── Branch 2: Knowledge ───────────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _hrKnowKey,
            routes: [
              GoRoute(
                path:    '/hr/knowledge',
                builder: (_, __) => const KnowledgeScreen(),
              ),
            ],
          ),

          // ── Branch 3: Profile + Settings ──────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _hrProfKey,
            routes: [
              GoRoute(
                path:    '/hr/profile',
                builder: (_, __) => const HRProfileScreen(),
              ),
              GoRoute(
                path:    '/hr/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Candidate Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _candidateShellKey,
        builder: (_, __, child) => CandidateShell(child: child),
        routes: [
          GoRoute(
            path:    '/candidate',
            builder: (_, __) => const CandidateHomeScreen(),
          ),
          GoRoute(
            path:    '/candidate/jobs',
            builder: (_, __) => const CandidateJobsScreen(),
            routes: [
              GoRoute(
                path:               ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) =>
                    JobDetailScreen(jobId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path:    '/candidate/practice',
            builder: (_, __) => const PracticeScreen(),
            routes: [
              GoRoute(
                path:               'session',
                parentNavigatorKey: _rootKey,
                builder:            (_, __) => const PracticeQuestionScreen(),
              ),
            ],
          ),
          GoRoute(
            path:    '/candidate/applications',
            builder: (_, __) => const ApplicationsScreen(),
          ),
          GoRoute(
            path:    '/candidate/profile',
            builder: (_, __) => const CandidateProfileScreen(),
          ),
        ],
      ),

      // ── Jobseeker full-screen routes (outside shell) ──────────────────────
      GoRoute(
        path:               '/jobseeker/practice/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            PracticeSessionScreen(setId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path:               'result',
            parentNavigatorKey: _rootKey,
            builder: (_, state) =>
                FeedbackScreen(setId: state.pathParameters['id']!),
          ),
        ],
      ),

      // ── Jobseeker Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _jobseekerShellKey,
        builder: (_, __, child) => JobseekerShell(child: child),
        routes: [
          GoRoute(
            path:    '/jobseeker/dashboard',
            builder: (_, __) => const JobseekerDashboardScreen(),
          ),
          GoRoute(
            path:    '/jobseeker',
            builder: (_, __) => const MarketplaceScreen(),
          ),
          GoRoute(
            path:    '/jobseeker/sets/:id',
            builder: (_, state) =>
                SetDetailScreen(setId: state.pathParameters['id']!),
          ),
          GoRoute(
            path:    '/jobseeker/history',
            builder: (_, __) => const JobseekerHistoryScreen(),
          ),
          GoRoute(
            path:    '/jobseeker/profile',
            builder: (_, __) => const JobseekerProfileScreen(),
          ),
          GoRoute(
            path:    '/jobseeker/settings',
            builder: (_, __) => const JobseekerSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

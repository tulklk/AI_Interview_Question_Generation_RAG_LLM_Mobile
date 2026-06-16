import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/app_providers.dart';
import '../../models/user_model.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/hr/screens/hr_shell.dart';
import '../../features/hr/screens/hr_dashboard_screen.dart';
import '../../features/hr/screens/jobs_screen.dart';
import '../../features/hr/screens/create_job_screen.dart';
import '../../features/hr/screens/ai_generator_screen.dart';
import '../../features/hr/screens/candidates_screen.dart';
import '../../features/hr/screens/candidate_detail_screen.dart';
import '../../features/hr/screens/interviews_screen.dart';
import '../../features/hr/screens/hr_profile_screen.dart';
import '../../features/candidate/screens/candidate_shell.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/candidate/screens/candidate_jobs_screen.dart';
import '../../features/candidate/screens/job_detail_screen.dart';
import '../../features/candidate/screens/practice_screen.dart';
import '../../features/candidate/screens/practice_question_screen.dart';
import '../../features/candidate/screens/applications_screen.dart';
import '../../features/candidate/screens/candidate_profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _hrShellKey = GlobalKey<NavigatorState>();
final _candidateShellKey = GlobalKey<NavigatorState>();

// Notifies GoRouter whenever auth state changes — without recreating the router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: notifier, // re-evaluates redirect on auth change
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLoggedIn = auth.user != null;
      final loc = state.matchedLocation;

      final isOnAuth = loc.startsWith('/splash') ||
          loc.startsWith('/onboarding') ||
          loc.startsWith('/role') ||
          loc.startsWith('/login') ||
          loc.startsWith('/register');

      // Not logged in → protect all non-auth routes
      if (!isLoggedIn && !isOnAuth) return '/splash';

      // Already logged in but still on login / role / register → go home
      if (isLoggedIn &&
          (loc.startsWith('/login') ||
              loc.startsWith('/role') ||
              loc.startsWith('/register'))) {
        return auth.user!.role == UserRole.hrManager ? '/hr' : '/candidate';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/role', builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── HR Shell ──────────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _hrShellKey,
        builder: (_, __, child) => HRShell(child: child),
        routes: [
          GoRoute(
            path: '/hr',
            builder: (_, __) => const HRDashboardScreen(),
            routes: [
              GoRoute(
                path: 'ai-generator',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const AIGeneratorScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/hr/jobs',
            builder: (_, __) => const JobsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const CreateJobScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/hr/candidates',
            builder: (_, __) => const CandidatesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) =>
                    CandidateDetailScreen(candidateId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/hr/interviews',
            builder: (_, __) => const InterviewsScreen(),
          ),
          GoRoute(
            path: '/hr/profile',
            builder: (_, __) => const HRProfileScreen(),
          ),
        ],
      ),

      // ── Candidate Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _candidateShellKey,
        builder: (_, __, child) => CandidateShell(child: child),
        routes: [
          GoRoute(
            path: '/candidate',
            builder: (_, __) => const CandidateHomeScreen(),
          ),
          GoRoute(
            path: '/candidate/jobs',
            builder: (_, __) => const CandidateJobsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) =>
                    JobDetailScreen(jobId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/candidate/practice',
            builder: (_, __) => const PracticeScreen(),
            routes: [
              GoRoute(
                path: 'session',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const PracticeQuestionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/candidate/applications',
            builder: (_, __) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/candidate/profile',
            builder: (_, __) => const CandidateProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../widgets/placeholder_screen.dart';
import 'app_shell.dart';

// ─── Route path constants ──────────────────────────────────────────────────

/// All named route paths used in the app.
///
/// Reference these constants when calling [context.go] or [context.push]
/// so path strings are never duplicated across the codebase.
abstract final class AppRoutes {
  // Auth
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  // Onboarding
  static const onboarding = '/onboarding';
  static const onboardingProperty = '/onboarding/property';
  static const onboardingTrial = '/onboarding/trial';

  // Tab 0 — Home
  static const dashboard = '/dashboard';
  static const home = '/home';
  static const homeSystems = '/home/systems';
  static const homeSystemsAdd = '/home/systems/add';
  static const homeSystemDetail = '/home/systems/:systemId';
  static const homeAppliances = '/home/appliances';
  static const homeAppliancesAdd = '/home/appliances/add';
  static const homeApplianceDetail = '/home/appliances/:applianceId';
  static const emergency = '/emergency';
  static const emergencyShutoffDetail = '/emergency/shutoffs/:type';
  static const emergencyContacts = '/emergency/contacts';
  static const emergencyContactsAdd = '/emergency/contacts/add';
  static const emergencyInsurance = '/emergency/insurance';

  // Tab 1 — Docs
  static const documents = '/documents';
  static const documentsUpload = '/documents/upload';
  static const documentsSearch = '/documents/search';
  static const documentsExpiring = '/documents/expiring';
  static const documentDetail = '/documents/:documentId';

  // Tab 2 — Tasks
  static const maintenance = '/maintenance';
  static const maintenanceTaskDetail = '/maintenance/:taskId';
  static const maintenanceCompleteTask = '/maintenance/complete/:taskId';

  // Tab 3 — Projects
  static const projects = '/projects';
  static const projectsCreate = '/projects/create';
  static const projectDetail = '/projects/:projectId';
  static const projectBudget = '/projects/:projectId/budget';
  static const projectPhotos = '/projects/:projectId/photos';
  static const projectNotes = '/projects/:projectId/notes';

  // Tab 4 — Settings
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsNotifications = '/settings/notifications';
  static const settingsSubscription = '/settings/subscription';
  static const settingsHousehold = '/settings/household';
  static const settingsExport = '/settings/export';
  static const settingsDeleteAccount = '/settings/delete-account';

  /// Public routes that do not require an authenticated session.
  static const Set<String> _publicRoutes = {
    login,
    signup,
    forgotPassword,
  };

  /// Returns true when [path] does not require an authenticated session.
  static bool isPublic(String path) => _publicRoutes.contains(path);
}

// ─── Router provider ───────────────────────────────────────────────────────

/// The single [GoRouter] instance for the app.
///
/// Watches [isAuthenticatedProvider] so the redirect callback re-evaluates
/// whenever authentication state changes without a manual router refresh.
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,

    redirect: (_, state) {
      final path = state.matchedLocation;
      final goingToPublic = AppRoutes.isPublic(path);

      // Unauthenticated user accessing a protected route → send to login.
      if (!isAuthenticated && !goingToPublic) {
        return AppRoutes.login;
      }

      // Authenticated user on an auth route → send to dashboard.
      if (isAuthenticated && goingToPublic) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [
      // ── Root redirect ────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (_, _) => AppRoutes.dashboard,
      ),

      // ── Auth routes (no shell) ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      // ── Onboarding routes (no shell) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const PlaceholderScreen(name: 'Welcome'),
      ),
      GoRoute(
        path: AppRoutes.onboardingProperty,
        builder: (_, _) => const PlaceholderScreen(name: 'Property Setup'),
      ),
      GoRoute(
        path: AppRoutes.onboardingTrial,
        builder: (_, _) => const PlaceholderScreen(name: 'Trial Offer'),
      ),

      // ── Shell — five tabs with persistent state ──────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ── Tab 0: Home ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, _) => const PlaceholderScreen(name: 'Home'),
              ),
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) =>
                    const PlaceholderScreen(name: 'Home Profile'),
                routes: [
                  GoRoute(
                    path: 'systems',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Systems'),
                    routes: [
                      // Static 'add' must come before parameterised ':systemId'.
                      GoRoute(
                        path: 'add',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Add System'),
                      ),
                      GoRoute(
                        path: ':systemId',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'System Detail'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'appliances',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Appliances'),
                    routes: [
                      // Static 'add' must come before parameterised ':applianceId'.
                      GoRoute(
                        path: 'add',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Add Appliance'),
                      ),
                      GoRoute(
                        path: ':applianceId',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Appliance Detail'),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.emergency,
                builder: (_, _) =>
                    const PlaceholderScreen(name: 'Emergency Hub'),
                routes: [
                  GoRoute(
                    path: 'shutoffs/:type',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Shutoff Detail'),
                  ),
                  GoRoute(
                    path: 'contacts',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Emergency Contacts'),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Add Contact'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'insurance',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Insurance Info'),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 1: Docs ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.documents,
                builder: (_, _) =>
                    const PlaceholderScreen(name: 'Document Vault'),
                routes: [
                  // Static segments must precede parameterised ':documentId'.
                  GoRoute(
                    path: 'upload',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Upload Document'),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Search Documents'),
                  ),
                  GoRoute(
                    path: 'expiring',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Expiring Documents'),
                  ),
                  GoRoute(
                    path: ':documentId',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Document Detail'),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 2: Tasks ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.maintenance,
                builder: (_, _) =>
                    const PlaceholderScreen(name: 'Maintenance'),
                routes: [
                  // Static 'complete/:taskId' must come before ':taskId'.
                  GoRoute(
                    path: 'complete/:taskId',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Complete Task'),
                  ),
                  GoRoute(
                    path: ':taskId',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Task Detail'),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 3: Projects ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.projects,
                builder: (_, _) => const PlaceholderScreen(name: 'Projects'),
                routes: [
                  // Static 'create' must come before parameterised ':projectId'.
                  GoRoute(
                    path: 'create',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Create Project'),
                  ),
                  GoRoute(
                    path: ':projectId',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Project Detail'),
                    routes: [
                      GoRoute(
                        path: 'budget',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Project Budget'),
                      ),
                      GoRoute(
                        path: 'photos',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Project Photos'),
                      ),
                      GoRoute(
                        path: 'notes',
                        builder: (_, _) =>
                            const PlaceholderScreen(name: 'Project Notes'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 4: Settings ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const PlaceholderScreen(name: 'Settings'),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Edit Profile'),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Notifications'),
                  ),
                  GoRoute(
                    path: 'subscription',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Subscription'),
                  ),
                  GoRoute(
                    path: 'household',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Household'),
                  ),
                  GoRoute(
                    path: 'export',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Export Data'),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Delete Account'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

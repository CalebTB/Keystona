import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/documents/screens/document_categories_screen.dart';
import '../../features/documents/screens/document_detail_screen.dart';
import '../../features/documents/screens/document_upload_screen.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/maintenance/models/maintenance_task.dart';
import '../../features/maintenance/screens/maintenance_screen.dart';
import '../../features/maintenance/screens/task_completion_form_screen.dart';
import '../../features/maintenance/screens/task_detail_screen.dart';
import '../../features/maintenance/screens/task_form_screen.dart';
import '../../features/home_profile/screens/home_profile_screen.dart';
import '../../features/onboarding/screens/property_setup_screen.dart';
import '../../features/onboarding/screens/trial_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
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
  static const home = '/home';
  static const homeSystems = '/home/systems';
  static const homeSystemsAdd = '/home/systems/add';
  static const homeSystemDetail = '/home/systems/:systemId';
  static const homeAppliances = '/home/appliances';
  static const homeAppliancesAdd = '/home/appliances/add';
  static const homeApplianceDetail = '/home/appliances/:applianceId';
  static const homeEdit = '/home/edit';
  static const homeLifespan = '/home/lifespan';
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
  static const documentsCategories = '/documents/categories';
  static const documentDetail = '/documents/:documentId';

  // Tab 2 — Tasks
  static const maintenance = '/maintenance';
  static const maintenanceCreate = '/maintenance/create';
  static const maintenanceEditTask = '/maintenance/edit/:taskId';
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
    onboarding,
    onboardingProperty,
    onboardingTrial,
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
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,

    redirect: (_, state) {
      final path = state.matchedLocation;
      final goingToPublic = AppRoutes.isPublic(path);

      // Unauthenticated user accessing a protected route → send to login.
      if (!isAuthenticated && !goingToPublic) {
        return AppRoutes.login;
      }

      // Authenticated user on an auth route → send to home.
      if (isAuthenticated && goingToPublic) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      // ── Root redirect ────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (_, _) => AppRoutes.home,
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
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingProperty,
        builder: (_, _) => const PropertySetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingTrial,
        builder: (_, _) => const TrialScreen(),
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
                path: AppRoutes.home,
                builder: (_, _) => const HomeProfileScreen(),
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
                  // [#41] Stub routes for downstream issues.
                  GoRoute(
                    path: 'edit',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Edit Property'),
                  ),
                  GoRoute(
                    path: 'lifespan',
                    builder: (_, _) =>
                        const PlaceholderScreen(name: 'Lifespan Tracker'),
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
                builder: (_, _) => const DocumentsScreen(),
                routes: [
                  // Static segments must precede parameterised ':documentId'.
                  GoRoute(
                    path: 'upload',
                    builder: (_, _) => const DocumentUploadScreen(),
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
                    path: 'categories',
                    builder: (_, _) => const DocumentCategoriesScreen(),
                  ),
                  GoRoute(
                    path: ':documentId',
                    builder: (_, state) => DocumentDetailScreen(
                      documentId: state.pathParameters['documentId']!,
                    ),
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
                builder: (_, _) => const MaintenanceScreen(),
                routes: [
                  // Static segments must come before parameterised ':taskId'.
                  GoRoute(
                    path: 'create',
                    builder: (_, _) => const TaskFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:taskId',
                    builder: (_, state) {
                      final task = state.extra as MaintenanceTask;
                      return TaskFormScreen(existingTask: task);
                    },
                  ),
                  GoRoute(
                    path: 'complete/:taskId',
                    builder: (_, state) => TaskCompletionFormScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':taskId',
                    builder: (_, state) => TaskDetailScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
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

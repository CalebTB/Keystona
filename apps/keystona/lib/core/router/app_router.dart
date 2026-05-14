import 'package:flutter/cupertino.dart';
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
import '../../features/emergency/models/emergency_contact.dart';
import '../../features/emergency/models/insurance_policy.dart';
import '../../features/emergency/screens/contact_form_screen.dart';
import '../../features/emergency/screens/contacts_list_screen.dart';
import '../../features/emergency/screens/emergency_hub_screen.dart';
import '../../features/emergency/screens/insurance_form_screen.dart';
import '../../features/emergency/screens/insurance_list_screen.dart';
import '../../features/emergency/screens/shutoff_detail_screen.dart';
import '../../features/home_profile/models/appliance.dart';
import '../../features/home_profile/models/system.dart';
import '../../features/home_profile/screens/appliance_detail_screen.dart';
import '../../features/home_profile/screens/appliance_form_screen.dart';
import '../../features/home_profile/screens/appliances_screen.dart';
import '../../features/home_profile/screens/home_profile_screen.dart';
import '../../features/home_profile/screens/lifespan_screen.dart';
import '../../features/home_profile/screens/system_detail_screen.dart';
import '../../features/projects/models/project.dart';
import '../../features/projects/models/project_budget_item.dart';
import '../../features/projects/models/project_journal_note.dart';
import '../../features/projects/models/project_phase.dart';
import '../../features/projects/screens/budget_item_form_screen.dart';
import '../../features/projects/screens/note_form_screen.dart';
import '../../features/projects/screens/phase_form_screen.dart';
import '../../features/projects/screens/phases_screen.dart';
import '../../features/projects/screens/project_budget_screen.dart';
import '../../features/projects/screens/project_contractors_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/projects/screens/project_documents_screen.dart';
import '../../features/projects/screens/project_form_screen.dart';
import '../../features/projects/screens/project_journal_screen.dart';
import '../../features/projects/screens/project_photos_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/home_profile/screens/system_form_screen.dart';
import '../../features/home_profile/screens/systems_screen.dart';
import '../../features/onboarding/screens/property_setup_screen.dart';
import '../../features/onboarding/screens/trial_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
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
  static const emergencyInsuranceAdd = '/emergency/insurance/add';
  static const emergencyInsuranceEdit = '/emergency/insurance/edit/:policyId';

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
  static const projectsEdit = '/projects/:projectId/edit';
  static const projectPhases = '/projects/:projectId/phases';
  static const projectPhaseCreate = '/projects/:projectId/phases/create';
  static const projectPhaseEdit = '/projects/:projectId/phases/:phaseId/edit';
  static const projectBudget = '/projects/:projectId/budget';
  static const projectBudgetCreate = '/projects/:projectId/budget/create';
  static const projectBudgetEdit =
      '/projects/:projectId/budget/:itemId/edit';
  static const projectPhotos = '/projects/:projectId/photos';
  static const projectNotes = '/projects/:projectId/notes';
  static const projectNotesCreate = '/projects/:projectId/notes/create';
  static const projectNotesEdit = '/projects/:projectId/notes/:noteId/edit';
  static const projectContractors = '/projects/:projectId/contractors';
  static const projectDocuments = '/projects/:projectId/documents';

  // Tab 4 — Settings
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsNotifications = '/settings/notifications';
  static const settingsSubscription = '/settings/subscription';
  static const settingsPaywall = '/settings/subscription/paywall';
  static const settingsHousehold = '/settings/household';
  static const settingsExport = '/settings/export';
  static const settingsDeleteAccount = '/settings/delete-account';

  /// Routes that do not require an authenticated session.
  static const Set<String> _publicRoutes = {
    login,
    signup,
    forgotPassword,
    onboarding,
    onboardingProperty,
    onboardingTrial,
  };

  /// Auth-only routes — authenticated users are redirected away from these.
  static const Set<String> _authOnlyRoutes = {
    login,
    signup,
    forgotPassword,
  };

  /// Returns true when [path] does not require an authenticated session.
  static bool isPublic(String path) => _publicRoutes.contains(path);

  /// Returns true when an authenticated user should be redirected away.
  static bool isAuthOnly(String path) => _authOnlyRoutes.contains(path);
}

// ─── Page builder helper ───────────────────────────────────────────────────

/// Returns a [CupertinoPage] for all pushed routes, giving iOS the native
/// slide-from-right transition and swipe-back gesture on every screen.
CupertinoPage<void> _buildPage(GoRouterState state, Widget child) =>
    CupertinoPage<void>(key: state.pageKey, child: child);

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

      // Authenticated user on a login/signup route → send to home.
      if (isAuthenticated && AppRoutes.isAuthOnly(path)) {
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
        pageBuilder: (_, state) => _buildPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (_, state) => _buildPage(state, const SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, state) => _buildPage(state, const ForgotPasswordScreen()),
      ),

      // ── Onboarding routes (no shell) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _buildPage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingProperty,
        pageBuilder: (_, state) => _buildPage(state, const PropertySetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingTrial,
        pageBuilder: (_, state) => _buildPage(state, const TrialScreen()),
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
                    pageBuilder: (_, state) =>
                        _buildPage(state, const SystemsScreen()),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          SystemFormScreen(
                            existingSystem: state.extra as HomeSystem?,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':systemId',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          SystemDetailScreen(
                            systemId: state.pathParameters['systemId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'appliances',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const AppliancesScreen()),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ApplianceFormScreen(
                            existingAppliance: state.extra as Appliance?,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':applianceId',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ApplianceDetailScreen(
                            applianceId:
                                state.pathParameters['applianceId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Edit Property'),
                    ),
                  ),
                  GoRoute(
                    path: 'lifespan',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const LifespanScreen()),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.emergency,
                pageBuilder: (_, state) =>
                    _buildPage(state, const EmergencyHubScreen()),
                routes: [
                  GoRoute(
                    path: 'shutoffs/:type',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      ShutoffDetailScreen(
                        utilityType: state.pathParameters['type']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'contacts',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const ContactsListScreen()),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ContactFormScreen(
                            existingContact:
                                state.extra as EmergencyContact?,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'insurance',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const InsuranceListScreen()),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (_, state) =>
                            _buildPage(state, const InsuranceFormScreen()),
                      ),
                      GoRoute(
                        path: 'edit/:policyId',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          InsuranceFormScreen(
                            existingPolicy: state.extra as InsurancePolicy,
                          ),
                        ),
                      ),
                    ],
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
                    pageBuilder: (_, state) =>
                        _buildPage(state, const DocumentUploadScreen()),
                  ),
                  GoRoute(
                    path: 'search',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Search Documents'),
                    ),
                  ),
                  GoRoute(
                    path: 'expiring',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Expiring Documents'),
                    ),
                  ),
                  GoRoute(
                    path: 'categories',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const DocumentCategoriesScreen()),
                  ),
                  GoRoute(
                    path: ':documentId',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      DocumentDetailScreen(
                        documentId: state.pathParameters['documentId']!,
                      ),
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
                    pageBuilder: (_, state) =>
                        _buildPage(state, const TaskFormScreen()),
                  ),
                  GoRoute(
                    path: 'edit/:taskId',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      TaskFormScreen(existingTask: state.extra as MaintenanceTask),
                    ),
                  ),
                  GoRoute(
                    path: 'complete/:taskId',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      TaskCompletionFormScreen(
                        taskId: state.pathParameters['taskId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':taskId',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      TaskDetailScreen(
                        taskId: state.pathParameters['taskId']!,
                      ),
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
                builder: (_, _) => const ProjectsScreen(),
                routes: [
                  // Static 'create' must come before parameterised ':projectId'.
                  GoRoute(
                    path: 'create',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const ProjectFormScreen()),
                  ),
                  GoRoute(
                    path: ':projectId',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      ProjectDetailScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      // Static 'edit' before downstream param routes.
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectFormScreen(
                            existingProject: state.extra as Project?,
                          ),
                        ),
                      ),
                      // #5.3 — Phases
                      GoRoute(
                        path: 'phases',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          PhasesScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                        routes: [
                          // Static 'create' before parameterised ':phaseId'.
                          GoRoute(
                            path: 'create',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              PhaseFormScreen(
                                projectId: state.pathParameters['projectId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':phaseId/edit',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              PhaseFormScreen(
                                projectId: state.pathParameters['projectId']!,
                                existingPhase: state.extra as ProjectPhase?,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'budget',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectBudgetScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'create',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              BudgetItemFormScreen(
                                projectId: state.pathParameters['projectId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':itemId/edit',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              BudgetItemFormScreen(
                                projectId: state.pathParameters['projectId']!,
                                existingItem: state.extra as ProjectBudgetItem?,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'photos',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectPhotosScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'notes',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectJournalScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'create',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              NoteFormScreen(
                                projectId: state.pathParameters['projectId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':noteId/edit',
                            pageBuilder: (_, state) => _buildPage(
                              state,
                              NoteFormScreen(
                                projectId: state.pathParameters['projectId']!,
                                existingNote: state.extra as ProjectJournalNote?,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'contractors',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectContractorsScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'documents',
                        pageBuilder: (_, state) => _buildPage(
                          state,
                          ProjectDocumentsScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
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
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Edit Profile'),
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Notifications'),
                    ),
                  ),
                  GoRoute(
                    path: 'subscription',
                    pageBuilder: (_, state) =>
                        _buildPage(state, const SubscriptionScreen()),
                    routes: [
                      GoRoute(
                        path: 'paywall',
                        pageBuilder: (_, state) =>
                            _buildPage(state, const PaywallScreen()),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'household',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Household'),
                    ),
                  ),
                  GoRoute(
                    path: 'export',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Export Data'),
                    ),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    pageBuilder: (_, state) => _buildPage(
                      state,
                      const PlaceholderScreen(name: 'Delete Account'),
                    ),
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

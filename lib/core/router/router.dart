import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../session/session_provider.dart';
import '../../data/models/models.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/welcome_choice_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/auth/screens/supply_chain_verification_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_approvals_screen.dart';
import '../../features/farmer/screens/farmer_dashboard_screen.dart';
import '../../features/chef/screens/chef_dashboard_screen.dart';
import '../../features/consumer/screens/consumer_dashboard_screen.dart';
import '../../features/aggregator/screens/aggregator_dashboard_screen.dart';
import '../../features/transporter/screens/transporter_dashboard_screen.dart';
import '../../features/distributor/screens/distributor_dashboard_screen.dart';
import '../../features/farmer/screens/new_batch_screen.dart';
import '../../features/farmer/screens/farm_documentation_screen.dart';
import '../../features/farmer/screens/irrigation_screen.dart';
import '../../features/farmer/screens/pest_screen.dart';
import '../../features/farmer/screens/harvest_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/farmer/screens/irrigation_advisor_screen.dart';
import '../../features/farmer/screens/climate_intelligence_screen.dart';
import '../../features/farmer/screens/farmer_batch_detail_screen.dart';
import '../../features/farmer/screens/farmer_pest_diagnosis_screen.dart';
import '../../features/farmer/screens/crop_recommendation_screen.dart';
import '../../features/farmer/screens/farmer_marketplace_screen.dart';
import '../../features/marketplace/screens/marketplace_home_screen.dart';
import '../../features/marketplace/screens/listing_detail_screen.dart';
import '../../features/marketplace/screens/request_produce_screen.dart';
import '../../features/marketplace/screens/agri_suppliers_screen.dart';
import '../../features/marketplace/screens/supplier_listing_detail_screen.dart';
import '../../features/marketplace/screens/supplier_request_screen.dart';
import '../../features/marketplace/screens/supplier_profile_screen.dart';
import '../../features/marketplace/screens/my_supplier_screen.dart';
import '../../features/marketplace/screens/my_requests_screen.dart';
import '../../features/marketplace/screens/conversation_screen.dart';
import '../../features/marketplace/screens/messages_inbox_screen.dart';
import '../../features/chef/screens/chef_meal_builder_screen.dart';
import '../../features/chef/screens/chef_meal_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/privacy_security_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/terms_of_service_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/manage_crops_screen.dart';
import '../../core/services/ai_vision_service.dart';

// Bridges Riverpod state changes into something GoRouter can listen to
// without rebuilding the whole router. This matters: previously
// `routerProvider` did `ref.watch(sessionProvider)` directly, so every
// sign-in, role selection, or sign-out rebuilt the entire GoRouter from
// scratch — which resets navigation to `initialLocation` ('/splash'),
// wiping out wherever the user actually was. That's what caused sign-in
// to appear to "redirect back to the splash screen": it wasn't a redirect,
// the whole router (and its navigation history) was being thrown away and
// recreated. Using `refreshListenable` instead lets GoRouter simply
// re-run `redirect` in place when auth state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(sessionProvider, (_, __) => notifyListeners());
    ref.listen(firebaseSignedInProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final fbSignedIn = ref.read(firebaseSignedInProvider).value ?? false;
      final path = state.matchedLocation;
      final isTransient = path == '/splash' || path == '/onboarding' || path == '/welcome';
      final isLogin = path == '/login';
      final isRoleSelect = path == '/role-select';
      final isVerifyRole = path.startsWith('/verify-role');
      final isPendingApproval = path == '/pending-approval';

      // Not signed in to Firebase AND no mock session → public pages only
      if (!fbSignedIn && session == null && !isTransient && !isLogin) {
        return '/login';
      }

      // Firebase signed in but Firestore doc not yet saved → pick role.
      // Note: this must fire even while sitting on /login (e.g. right after
      // sign-up), otherwise the user gets stuck there post-authentication.
      // /verify-role is exempt too — a user lands there BEFORE setRole is
      // called (invite-code/request-access happens first), so session is
      // still null at that point; without this exemption they'd bounce
      // straight back to /role-select the instant they tap a supply-chain
      // role card.
      if (fbSignedIn && session == null && !isRoleSelect && !isTransient && !isVerifyRole) {
        return '/role-select';
      }

      // Supply-chain role (Aggregator/Transporter/Distributor) whose
      // verification hasn't cleared yet — hold on the Pending screen
      // instead of letting them into a dashboard that can touch other
      // people's produce. `approved`/`none` (the latter covers Farmer/
      // Chef/Grocery Shopper, which don't need verification) pass through.
      if (session != null &&
          kSupplyChainRoles.contains(session.role) &&
          session.verificationStatus != VerificationStatus.approved &&
          !isPendingApproval &&
          !isVerifyRole) {
        return '/pending-approval';
      }

      // Has full session → redirect away from public/role pages
      if (session != null &&
          (isTransient || isLogin || isRoleSelect) &&
          !(kSupplyChainRoles.contains(session.role) &&
              session.verificationStatus != VerificationStatus.approved)) {
        return session.role.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeChoiceScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) =>
            LoginScreen(startInSignUp: state.extra == true),
      ),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/verify-role/:role',
        builder: (_, state) {
          final role = UserRole.values.byName(state.pathParameters['role']!);
          return SupplyChainVerificationScreen(role: role);
        },
      ),
      GoRoute(path: '/pending-approval', builder: (_, __) => const PendingApprovalScreen()),
      GoRoute(path: '/admin/approvals', builder: (_, __) => const AdminApprovalsScreen()),

      // Farmer
      GoRoute(path: '/farmer', builder: (_, __) => const FarmerDashboardScreen()),
      GoRoute(path: '/farmer/batches/new', builder: (_, __) => const NewBatchScreen()),
      GoRoute(path: '/farmer/batches/irrigation', builder: (_, __) => const IrrigationScreen()),
      GoRoute(path: '/farmer/batches/pest', builder: (_, __) => const PestScreen()),
      GoRoute(path: '/farmer/batches/harvest', builder: (_, __) => const HarvestLogScreen()),
      GoRoute(path: '/farmer/trace', builder: (_, __) => const ScannerScreen()),
      GoRoute(
        path: '/farmer/documents/new',
        builder: (_, state) {
          final typeParam = state.uri.queryParameters['type'];
          final type = FarmDocumentType.values
              .firstWhere((t) => t.name == typeParam, orElse: () => FarmDocumentType.fertilizer);
          return FarmDocumentationScreen(initialType: type);
        },
      ),
      GoRoute(path: '/farmer/irrigation-advisor', builder: (_, __) => const IrrigationAdvisorScreen()),
      GoRoute(path: '/farmer/climate-intelligence', builder: (_, __) => const ClimateIntelligenceScreen()),
      GoRoute(path: '/farmer/marketplace', builder: (_, __) => const FarmerMarketplaceScreen()),
      GoRoute(
        path: '/farmer/batches/:id',
        builder: (_, state) =>
            FarmerBatchDetailScreen(batchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/batches/:id/scan',
        builder: (_, state) => FarmerPestDiagnosisScreen(
          batchId: state.pathParameters['id']!,
          cropName: state.uri.queryParameters['crop'] ?? 'Tomatoes',
        ),
      ),
      GoRoute(
        path: '/farmer/plan-crop',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CropRecommendationScreen(
            previousCropName: extra?['previousCropName'] as String? ?? 'Tomatoes',
            diagnosis: extra?['diagnosis'] as VisionDiagnosisResult? ??
                const VisionDiagnosisResult(
                  isHealthy: true,
                  label: 'Healthy',
                  confidence: 1,
                  severity: PestSeverity.low,
                  summary: 'No prior diagnosis on file - showing general rotation advice.',
                ),
            phiClearDate: extra?['phiClearDate'] as DateTime?,
          );
        },
      ),

      // Chef
      GoRoute(path: '/chef', builder: (_, __) => const ChefDashboardScreen()),
      GoRoute(path: '/chef/meal-builder', builder: (_, __) => const ChefMealBuilderScreen()),
      GoRoute(
        path: '/chef/meal/:id',
        builder: (_, state) => ChefMealDetailScreen(mealId: state.pathParameters['id']!),
      ),

      // Aggregator
      GoRoute(path: '/aggregator', builder: (_, __) => const AggregatorDashboardScreen()),

      // Transporter
      GoRoute(path: '/transporter', builder: (_, __) => const TransporterDashboardScreen()),

      // Distributor
      GoRoute(path: '/distributor', builder: (_, __) => const DistributorDashboardScreen()),

      // Shared
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/privacy-security', builder: (_, __) => const PrivacySecurityScreen()),
      GoRoute(path: '/settings/manage-crops', builder: (_, __) => const ManageCropsScreen()),
      GoRoute(path: '/settings/help-support', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/settings/terms', builder: (_, __) => const TermsOfServiceScreen()),
      GoRoute(path: '/settings/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),

      // Consumer
      GoRoute(path: '/consumer', builder: (_, __) => const ConsumerDashboardScreen()),
      GoRoute(
        path: '/consumer/scan/:id',
        builder: (context, state) => TraceResultScreen(
          batchId: state.pathParameters['id']!,
          onReset: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/consumer/meal/:id',
        builder: (context, state) => MealTraceResultScreen(
          mealId: state.pathParameters['id']!,
          onReset: () => context.pop(),
        ),
      ),

      // Marketplace (shared — farmer entry point is /farmer/marketplace above)
      GoRoute(path: '/marketplace', builder: (_, __) => const MarketplaceHomeScreen()),
      GoRoute(
        path: '/marketplace/listing/:id',
        builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/marketplace/listing/:id/request',
        builder: (_, state) => RequestProduceScreen(listingId: state.pathParameters['id']!),
      ),

      // Agricultural Suppliers (sections 18-22) — reuses the same
      // MarketplaceRequest/status machinery as produce, via
      // MarketplaceRequestTarget, rather than a parallel system.
      GoRoute(path: '/marketplace/suppliers', builder: (_, __) => const AgriSuppliersScreen()),
      GoRoute(
        path: '/marketplace/suppliers/listing/:id',
        builder: (_, state) =>
            SupplierListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/marketplace/suppliers/listing/:id/request',
        builder: (_, state) =>
            SupplierRequestScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/marketplace/suppliers/profile/:id',
        builder: (_, state) =>
            SupplierProfileScreen(supplierId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/marketplace/my-supplier', builder: (_, __) => const MySupplierScreen()),
      GoRoute(path: '/marketplace/my-requests', builder: (_, __) => const MyRequestsScreen()),

      // Messaging — always anchored to a request (section 13), never a
      // free-standing DM system.
      GoRoute(path: '/messages', builder: (_, __) => const MessagesInboxScreen()),
      GoRoute(
        path: '/messages/request/:requestId',
        builder: (_, state) =>
            ConversationScreen(requestId: state.pathParameters['requestId']!),
      ),

      // Shared QR
      GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
    ],
  );
});

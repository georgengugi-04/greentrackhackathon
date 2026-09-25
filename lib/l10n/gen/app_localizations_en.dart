// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Cultivating Conscious Consumption';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonFullName => 'Full Name';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSignIn => 'Sign In';

  @override
  String get commonSignUp => 'Sign Up';

  @override
  String get loginCreateAccountButton => 'Create Account';

  @override
  String get loginWelcomeBack => 'Welcome back.';

  @override
  String get loginCreateAccount => 'Create account.';

  @override
  String get loginSignInSubtitle => 'Sign in to your account';

  @override
  String get loginJoinSubtitle => 'Join the GreenTrack network';

  @override
  String get loginFullNameHint => 'Mwangi Kamau';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginNoAccount => 'Already have an account? ';

  @override
  String get loginNoAccountYet => 'Don\'t have an account? ';

  @override
  String get loginEmailHint => 'your@email.com';

  @override
  String get errorEnterEmailFirst =>
      'Enter your email above first, then tap \"Forgot password?\"';

  @override
  String get loginQuickAccessDev => 'QUICK ACCESS (DEV)';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleChef => 'Chef';

  @override
  String get roleConsumer => 'Consumer';

  @override
  String get roleAggregator => 'Aggregator';

  @override
  String get roleTransporter => 'Transporter';

  @override
  String get roleDistributor => 'Distributor';

  @override
  String get errorEnterEmailPassword => 'Please enter your email and password.';

  @override
  String get errorEnterName => 'Please enter your name.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorNoAccountFound => 'No account found with this email.';

  @override
  String get errorIncorrectEmailPassword => 'Incorrect email or password.';

  @override
  String get errorIncorrectEmailPasswordGoogleHint =>
      'Incorrect email or password. If you originally signed up with Google, use \"Continue with Google\" below instead.';

  @override
  String get errorEmailSignInNotEnabled =>
      'Email/password sign-in isn\'t enabled for this app yet. Contact the app admin, or try \"Continue with Google\" below.';

  @override
  String get errorAccountExists => 'An account with this email already exists.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorSignInTimeout =>
      'Sign-in timed out — check your connection (an ad blocker or privacy extension can also block this) and try again.';

  @override
  String get errorSignInFailed => 'Sign in failed. Please try again.';

  @override
  String get errorGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get errorGoogleSignInNotConfigured =>
      'Google sign-in isn\'t configured for this app build yet (missing SHA-1 in Firebase). Contact support.';

  @override
  String passwordResetLinkSent(String email) {
    return 'Password reset link sent to $email';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSwahili => 'Kiswahili';

  @override
  String get marketplaceTitle => 'Marketplace';

  @override
  String get marketplaceMyRequests => 'My Requests';

  @override
  String get marketplaceMessages => 'Messages';

  @override
  String get marketplaceTagline =>
      'Find fresh produce, upcoming harvests and trusted agricultural suppliers.';

  @override
  String get marketplaceSearchHint => 'Search crops, e.g. Spinach';

  @override
  String get marketplaceFilters => 'Filters';

  @override
  String get marketplaceViewAll => 'All';

  @override
  String get marketplaceViewAvailableNow => 'Available Now';

  @override
  String get marketplaceViewHarvestingSoon => 'Harvesting Soon';

  @override
  String get marketplaceTraceABatch => 'Trace a Batch';

  @override
  String get marketplaceFreshProduce => 'Fresh Produce';

  @override
  String get marketplaceErrorLoadListings =>
      'We couldn\'t load marketplace listings. Please try again.';

  @override
  String get marketplaceNoProduceMatch => 'No produce matches your search';

  @override
  String get marketplaceNoProduceAvailable => 'No produce available right now';

  @override
  String get marketplaceTryWideningFilters => 'Try widening your filters.';

  @override
  String get marketplaceCheckBackSoon =>
      'Check back soon, or follow an upcoming harvest below.';

  @override
  String get marketplaceErrorLoadHarvests =>
      'We couldn\'t load upcoming harvests. Please try again.';

  @override
  String get marketplaceNoHarvestsMatch =>
      'No upcoming harvests match your search';

  @override
  String get marketplaceNoHarvestsYet => 'No upcoming harvests yet.';

  @override
  String get marketplaceAgriSuppliers => 'Agri Suppliers';

  @override
  String get marketplaceViewAllLink => 'View all';

  @override
  String get marketplaceSuppliersBlurb => 'Seeds, fertiliser, equipment & more';

  @override
  String get marketplaceFilterProduce => 'Filter Produce';

  @override
  String get marketplaceLocation => 'Location';

  @override
  String get marketplaceLocationHint => 'e.g. Nakuru';

  @override
  String get marketplaceMinQuantity => 'Minimum quantity';

  @override
  String get marketplaceMaxPrice => 'Maximum price (KSh, optional)';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonApply => 'Apply';

  @override
  String marketplaceFreshCropName(String crop) {
    return 'Fresh $crop';
  }

  @override
  String marketplaceEstQuantity(String qty, String unit) {
    return 'Est. $qty $unit';
  }

  @override
  String marketplaceExpectedDate(String date) {
    return ' · Expected $date';
  }

  @override
  String marketplaceAvailableQuantity(String qty, String unit) {
    return '$qty $unit available';
  }

  @override
  String marketplaceHarvestedDate(String date) {
    return ' · Harvested $date';
  }

  @override
  String marketplacePriceLine(String price, String unit) {
    return 'KSh $price/$unit';
  }

  @override
  String get suppliersTitle => 'Agri Suppliers';

  @override
  String get suppliersSellHere => 'Sell here';

  @override
  String get suppliersSearchHint => 'Search seeds, fertilizer, equipment…';

  @override
  String get suppliersAll => 'All';

  @override
  String get suppliersErrorLoad =>
      'We couldn\'t load suppliers. Please try again.';

  @override
  String get suppliersNoneYet => 'No supplier listings yet';

  @override
  String get suppliersNoneYetMessage =>
      'Check back soon, or register your business to list here.';

  @override
  String suppliersPriceLine(String price) {
    return 'KSh $price';
  }

  @override
  String get listingTitle => 'Listing';

  @override
  String get listingErrorLoad => 'We couldn\'t load this listing.';

  @override
  String get listingNoLongerAvailable => 'This listing is no longer available.';

  @override
  String get listingNotHarvestedBanner =>
      'This crop has not yet been harvested. Estimated quantity may change at harvest.';

  @override
  String get listingExpectedHarvest => 'Expected harvest';

  @override
  String get listingHarvested => 'Harvested';

  @override
  String get listingDateTbd => 'TBD';

  @override
  String get listingDateUnknown => 'Unknown';

  @override
  String get listingLocation => 'Location';

  @override
  String get listingFarmer => 'Farmer';

  @override
  String get listingBatch => 'Batch';

  @override
  String get listingStatus => 'Status';

  @override
  String get listingTraceThisBatch => 'Trace This Batch';

  @override
  String get listingFollowingThis => 'You\'re following this';

  @override
  String get listingNotifyMe => 'Notify Me';

  @override
  String get listingSoldOut => 'Sold Out';

  @override
  String get listingRequestProduce => 'Request Produce';

  @override
  String get listingPaymentDisclaimer =>
      'Payment and delivery arrangements are handled directly between the buyer and seller.';

  @override
  String get requestTitle => 'Request Produce';

  @override
  String requestQuantityLabel(String unit) {
    return 'Quantity ($unit)';
  }

  @override
  String get requestQuantityHint => 'e.g. 10';

  @override
  String get requestIntendedUse => 'Intended use';

  @override
  String get requestFulfilmentPreference => 'Fulfilment preference';

  @override
  String get requestPreferredDate => 'Preferred date (optional)';

  @override
  String get requestChooseDate => 'Choose a date';

  @override
  String get requestMessage => 'Message (optional)';

  @override
  String get requestMessageHint => 'Anything the farmer should know';

  @override
  String get requestSend => 'Send Request';

  @override
  String get requestErrorInvalidQuantity => 'Enter a valid quantity.';

  @override
  String get requestErrorQuantityTooHigh =>
      'Requested quantity is greater than the available quantity.';

  @override
  String get requestSentToFarmer => 'Request sent to the farmer.';

  @override
  String requestErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get farmerMarketplaceTitle => 'My Marketplace';

  @override
  String get farmerMarketplaceMyListings => 'My Listings';

  @override
  String get farmerMarketplaceRequests => 'Requests';

  @override
  String get farmerMarketplaceErrorListings =>
      'We couldn\'t load your listings.';

  @override
  String get farmerMarketplaceNoListings => 'No marketplace listings yet';

  @override
  String get farmerMarketplaceNoListingsMessage =>
      'Publish a harvest from Log Harvest to see it here.';

  @override
  String get farmerMarketplaceErrorRequests =>
      'We couldn\'t load your requests.';

  @override
  String get farmerMarketplaceNoRequests => 'No requests yet';

  @override
  String get farmerMarketplaceNoRequestsMessage =>
      'Buyer requests on your listings will show up here.';

  @override
  String farmerMarketplaceRemaining(
      String available, String total, String unit) {
    return '$available/$total $unit remaining';
  }

  @override
  String requestBuyerQuantity(String name, String qty, String unit) {
    return '$name · $qty $unit';
  }

  @override
  String requestPreferredLabel(String date) {
    return 'Preferred: $date';
  }

  @override
  String get commonMessage => 'Message';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonMarkFulfilled => 'Mark Fulfilled';

  @override
  String get supplierListingTitle => 'Supplier Product';

  @override
  String get supplierListingErrorLoad => 'We couldn\'t load this listing.';

  @override
  String get supplierListingNoLongerAvailable =>
      'This listing is no longer available.';

  @override
  String get supplierListingRequestProduct => 'Request Product';

  @override
  String get supplierListingPaymentDisclaimer =>
      'Payment and delivery arrangements are handled directly between you and the supplier.';

  @override
  String get supplierRequestQuantity => 'Quantity';

  @override
  String get supplierRequestUnit => 'Unit';

  @override
  String get supplierRequestUnitHint => 'bags';

  @override
  String get supplierRequestMessageHint =>
      'e.g. Need fertiliser suitable for spinach';

  @override
  String get supplierRequestSupplierUnavailable =>
      'This supplier is no longer available.';

  @override
  String get supplierRequestSentToSupplier => 'Request sent to the supplier.';

  @override
  String get supplierRequestDefaultUnit => 'units';

  @override
  String get supplierProfileTitle => 'Supplier Profile';

  @override
  String get supplierProfileErrorLoad => 'We couldn\'t load this supplier.';

  @override
  String get supplierProfileUnavailable =>
      'This supplier is no longer available.';

  @override
  String get supplierProfileVerified => 'Verified Supplier';

  @override
  String get supplierProfileCategory => 'Category';

  @override
  String get supplierProfileLocation => 'Location';

  @override
  String get supplierProfileProductsServices => 'Products & Services';

  @override
  String get supplierProfileErrorListings =>
      'We couldn\'t load this supplier\'s listings.';

  @override
  String get supplierProfileNoActiveListings => 'No active listings right now.';

  @override
  String get mySupplierBecomeSupplier => 'Become a Supplier';

  @override
  String get mySupplierIntro =>
      'List seeds, fertiliser, equipment or services to farmers on GreenTrack.';

  @override
  String get mySupplierBusinessName => 'Business name';

  @override
  String get mySupplierGeneralLocation => 'General location';

  @override
  String get mySupplierDescription => 'Description';

  @override
  String get mySupplierContactPhone => 'Contact phone (optional)';

  @override
  String get mySupplierContactEmail => 'Contact email (optional)';

  @override
  String get mySupplierRegisterButton => 'Register as Supplier';

  @override
  String get mySupplierPendingNotice =>
      'New supplier accounts are reviewed before the \"Verified Supplier\" badge appears. You can still list products while pending review.';

  @override
  String get mySupplierErrorRequiredFields =>
      'Business name and location are required.';

  @override
  String get marketplaceTitleShort => 'Marketplace';

  @override
  String get mySupplierMyListings => 'My Listings';

  @override
  String get mySupplierRequests => 'Requests';

  @override
  String get mySupplierAddListing => 'Add Listing';

  @override
  String get mySupplierNoListings => 'No listings yet';

  @override
  String get mySupplierNoListingsMessage =>
      'Add your first product or service above.';

  @override
  String get mySupplierNoRequests => 'No requests yet';

  @override
  String get mySupplierNoRequestsMessage =>
      'Farmer requests for your products will show up here.';

  @override
  String get mySupplierRejectedNotice =>
      'Your supplier account was not approved. Contact support for details.';

  @override
  String get mySupplierPendingBanner =>
      'Your supplier account is pending verification. Listings are live, but the \"Verified\" badge appears once approved.';

  @override
  String get mySupplierActive => 'Active';

  @override
  String get mySupplierPaused => 'Paused';

  @override
  String get commonPause => 'Pause';

  @override
  String get commonResume => 'Resume';

  @override
  String get mySupplierProductName => 'Product/service name';

  @override
  String get mySupplierPrice => 'Price (optional)';

  @override
  String get mySupplierUnit => 'Unit (optional)';

  @override
  String get mySupplierUnitHint => 'bag, litre';

  @override
  String get mySupplierPublishListing => 'Publish Listing';

  @override
  String get mySupplierErrorEnterName => 'Enter a product/service name.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesErrorLoad => 'We couldn\'t load your messages.';

  @override
  String get messagesNoConversations => 'No conversations yet';

  @override
  String get messagesNoConversationsMessage =>
      'Chats open once you request produce or a supplier product.';

  @override
  String get messagesNoMessagesYet => 'No messages yet';

  @override
  String get messagesConversationFallback => 'Conversation';

  @override
  String get conversationTitle => 'Conversation';

  @override
  String get conversationErrorOpen => 'Could not open this conversation.';

  @override
  String get conversationErrorLoad => 'We couldn\'t load this conversation.';

  @override
  String get conversationRequestUnavailable =>
      'This request is no longer available.';

  @override
  String get conversationRequestFallback => 'Request';

  @override
  String get conversationErrorLoadMessages => 'We couldn\'t load messages.';

  @override
  String get conversationSayHello =>
      'Say hello — this is where you and the other party talk.';

  @override
  String get conversationHint => 'Message…';

  @override
  String get myRequestsTitle => 'My Requests';

  @override
  String get myRequestsNoneYet => 'No requests yet';

  @override
  String get myRequestsNoneYetMessage =>
      'Requests you send for produce or supplier products show up here.';

  @override
  String get adminAccessRequestsTitle => 'Access Requests';

  @override
  String get adminRoleRequestsTab => 'Role Requests';

  @override
  String get adminSuppliersTab => 'Suppliers';

  @override
  String adminErrorVerifyAccess(String error) {
    return 'Could not verify admin access: $error';
  }

  @override
  String get adminNotAuthorized => 'Not Authorized';

  @override
  String get adminNoAdminAccess => 'This account doesn\'t have admin access.';

  @override
  String adminErrorLoadRequests(String error) {
    return 'Could not load requests: $error';
  }

  @override
  String get adminNoPendingRequests => 'No pending requests';

  @override
  String adminApproved(String name) {
    return '$name approved';
  }

  @override
  String adminRejected(String name) {
    return '$name rejected';
  }

  @override
  String adminErrorSaveDecision(String error) {
    return 'Could not save decision: $error';
  }

  @override
  String get commonReject => 'Reject';

  @override
  String get commonApprove => 'Approve';

  @override
  String get commonVerify => 'Verify';

  @override
  String adminErrorLoadSuppliers(String error) {
    return 'Could not load suppliers: $error';
  }

  @override
  String get adminNoSuppliersAwaiting => 'No suppliers awaiting verification';

  @override
  String adminSupplierVerified(String name) {
    return '$name verified';
  }

  @override
  String get consumerGreetingFallbackName => 'there';

  @override
  String get consumerGoodMorning => 'Good Morning';

  @override
  String get consumerGoodAfternoon => 'Good Afternoon';

  @override
  String get consumerGoodEvening => 'Good Evening';

  @override
  String get consumerPlateTagline => 'Know exactly what\'s on your plate 🍽️';

  @override
  String get statScans => 'Scans';

  @override
  String get statTotalTraced => 'Total traced';

  @override
  String get statOrganic => 'Organic';

  @override
  String get statVerified => 'Verified';

  @override
  String get statMeals => 'Meals';

  @override
  String get statTraced => 'Traced';

  @override
  String get dashboardMarketplaceTitle => 'Marketplace';

  @override
  String get dashboardMarketplaceSubtitle =>
      'Fresh produce & upcoming harvests';

  @override
  String get dashboardMarketplaceDescription =>
      'Browse, follow a harvest, or request produce.';

  @override
  String get consumerRecentScans => 'Recent Scans';

  @override
  String get consumerScanQrCode => 'Scan a QR code';

  @override
  String get consumerScanQrSubtitle => 'Product packaging or restaurant menu';

  @override
  String get consumerNoScansYet => 'No scans yet';

  @override
  String get consumerNoScansMessage =>
      'Scan a product\'s QR code and it\'ll show up here — nothing\nis shown until you actually scan something.';

  @override
  String get consumerScanFirstProduct => 'Scan your first product';

  @override
  String get consumerOrganicBadge => 'Organic';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsEditProfileSubtitle =>
      'Tap your photo on the profile page to change it';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsNoEmailOnFile => 'No email on file';

  @override
  String settingsSendResetLinkTo(String email) {
    return 'Send a reset link to $email';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationCenter => 'Notification Center';

  @override
  String get settingsNotificationCenterSubtitle =>
      'Batch alerts, PHI reminders, and updates';

  @override
  String get settingsPrivacySupport => 'Privacy & Support';

  @override
  String get settingsPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsPrivacySecuritySubtitle =>
      'Data usage, permissions, manage crops';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQs and contact';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsAdmin => 'Admin';

  @override
  String get settingsAccessRequests => 'Access Requests';

  @override
  String get settingsAccessRequestsSubtitle =>
      'Review pending supply-chain sign-ups';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsVersionLabel => 'Version 1.0.0';

  @override
  String get settingsNoEmailSnackbar => 'No email on file for this account';

  @override
  String get settingsResetEmailFailed =>
      'Could not send reset email. Please try again.';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmBody =>
      'You\'ll need to sign in again to access your account.';
}

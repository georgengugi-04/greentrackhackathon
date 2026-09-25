import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw')
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Cultivating Conscious Consumption'**
  String get appTagline;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get commonFullName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get commonSignIn;

  /// No description provided for @commonSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get commonSignUp;

  /// No description provided for @loginCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccountButton;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get loginWelcomeBack;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account.'**
  String get loginCreateAccount;

  /// No description provided for @loginSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginSignInSubtitle;

  /// No description provided for @loginJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the GreenTrack network'**
  String get loginJoinSubtitle;

  /// No description provided for @loginFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mwangi Kamau'**
  String get loginFullNameHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginNoAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccountYet;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get loginEmailHint;

  /// No description provided for @errorEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first, then tap \"Forgot password?\"'**
  String get errorEnterEmailFirst;

  /// No description provided for @loginQuickAccessDev.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACCESS (DEV)'**
  String get loginQuickAccessDev;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleChef.
  ///
  /// In en, this message translates to:
  /// **'Chef'**
  String get roleChef;

  /// No description provided for @roleConsumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get roleConsumer;

  /// No description provided for @roleAggregator.
  ///
  /// In en, this message translates to:
  /// **'Aggregator'**
  String get roleAggregator;

  /// No description provided for @roleTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get roleTransporter;

  /// No description provided for @roleDistributor.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get roleDistributor;

  /// No description provided for @errorEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get errorEnterEmailPassword;

  /// No description provided for @errorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get errorEnterName;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorNoAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorNoAccountFound;

  /// No description provided for @errorIncorrectEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorIncorrectEmailPassword;

  /// No description provided for @errorIncorrectEmailPasswordGoogleHint.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. If you originally signed up with Google, use \"Continue with Google\" below instead.'**
  String get errorIncorrectEmailPasswordGoogleHint;

  /// No description provided for @errorEmailSignInNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email/password sign-in isn\'t enabled for this app yet. Contact the app admin, or try \"Continue with Google\" below.'**
  String get errorEmailSignInNotEnabled;

  /// No description provided for @errorAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorAccountExists;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorSignInTimeout.
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out — check your connection (an ad blocker or privacy extension can also block this) and try again.'**
  String get errorSignInTimeout;

  /// No description provided for @errorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get errorSignInFailed;

  /// No description provided for @errorGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get errorGoogleSignInFailed;

  /// No description provided for @errorGoogleSignInNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in isn\'t configured for this app build yet (missing SHA-1 in Firebase). Contact support.'**
  String get errorGoogleSignInNotConfigured;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}'**
  String passwordResetLinkSent(String email);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get settingsLanguageSwahili;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get marketplaceMyRequests;

  /// No description provided for @marketplaceMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get marketplaceMessages;

  /// No description provided for @marketplaceTagline.
  ///
  /// In en, this message translates to:
  /// **'Find fresh produce, upcoming harvests and trusted agricultural suppliers.'**
  String get marketplaceTagline;

  /// No description provided for @marketplaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search crops, e.g. Spinach'**
  String get marketplaceSearchHint;

  /// No description provided for @marketplaceFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get marketplaceFilters;

  /// No description provided for @marketplaceViewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get marketplaceViewAll;

  /// No description provided for @marketplaceViewAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get marketplaceViewAvailableNow;

  /// No description provided for @marketplaceViewHarvestingSoon.
  ///
  /// In en, this message translates to:
  /// **'Harvesting Soon'**
  String get marketplaceViewHarvestingSoon;

  /// No description provided for @marketplaceTraceABatch.
  ///
  /// In en, this message translates to:
  /// **'Trace a Batch'**
  String get marketplaceTraceABatch;

  /// No description provided for @marketplaceFreshProduce.
  ///
  /// In en, this message translates to:
  /// **'Fresh Produce'**
  String get marketplaceFreshProduce;

  /// No description provided for @marketplaceErrorLoadListings.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load marketplace listings. Please try again.'**
  String get marketplaceErrorLoadListings;

  /// No description provided for @marketplaceNoProduceMatch.
  ///
  /// In en, this message translates to:
  /// **'No produce matches your search'**
  String get marketplaceNoProduceMatch;

  /// No description provided for @marketplaceNoProduceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No produce available right now'**
  String get marketplaceNoProduceAvailable;

  /// No description provided for @marketplaceTryWideningFilters.
  ///
  /// In en, this message translates to:
  /// **'Try widening your filters.'**
  String get marketplaceTryWideningFilters;

  /// No description provided for @marketplaceCheckBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, or follow an upcoming harvest below.'**
  String get marketplaceCheckBackSoon;

  /// No description provided for @marketplaceErrorLoadHarvests.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load upcoming harvests. Please try again.'**
  String get marketplaceErrorLoadHarvests;

  /// No description provided for @marketplaceNoHarvestsMatch.
  ///
  /// In en, this message translates to:
  /// **'No upcoming harvests match your search'**
  String get marketplaceNoHarvestsMatch;

  /// No description provided for @marketplaceNoHarvestsYet.
  ///
  /// In en, this message translates to:
  /// **'No upcoming harvests yet.'**
  String get marketplaceNoHarvestsYet;

  /// No description provided for @marketplaceAgriSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Agri Suppliers'**
  String get marketplaceAgriSuppliers;

  /// No description provided for @marketplaceViewAllLink.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get marketplaceViewAllLink;

  /// No description provided for @marketplaceSuppliersBlurb.
  ///
  /// In en, this message translates to:
  /// **'Seeds, fertiliser, equipment & more'**
  String get marketplaceSuppliersBlurb;

  /// No description provided for @marketplaceFilterProduce.
  ///
  /// In en, this message translates to:
  /// **'Filter Produce'**
  String get marketplaceFilterProduce;

  /// No description provided for @marketplaceLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get marketplaceLocation;

  /// No description provided for @marketplaceLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nakuru'**
  String get marketplaceLocationHint;

  /// No description provided for @marketplaceMinQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity'**
  String get marketplaceMinQuantity;

  /// No description provided for @marketplaceMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum price (KSh, optional)'**
  String get marketplaceMaxPrice;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @marketplaceFreshCropName.
  ///
  /// In en, this message translates to:
  /// **'Fresh {crop}'**
  String marketplaceFreshCropName(String crop);

  /// No description provided for @marketplaceEstQuantity.
  ///
  /// In en, this message translates to:
  /// **'Est. {qty} {unit}'**
  String marketplaceEstQuantity(String qty, String unit);

  /// No description provided for @marketplaceExpectedDate.
  ///
  /// In en, this message translates to:
  /// **' · Expected {date}'**
  String marketplaceExpectedDate(String date);

  /// No description provided for @marketplaceAvailableQuantity.
  ///
  /// In en, this message translates to:
  /// **'{qty} {unit} available'**
  String marketplaceAvailableQuantity(String qty, String unit);

  /// No description provided for @marketplaceHarvestedDate.
  ///
  /// In en, this message translates to:
  /// **' · Harvested {date}'**
  String marketplaceHarvestedDate(String date);

  /// No description provided for @marketplacePriceLine.
  ///
  /// In en, this message translates to:
  /// **'KSh {price}/{unit}'**
  String marketplacePriceLine(String price, String unit);

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Agri Suppliers'**
  String get suppliersTitle;

  /// No description provided for @suppliersSellHere.
  ///
  /// In en, this message translates to:
  /// **'Sell here'**
  String get suppliersSellHere;

  /// No description provided for @suppliersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search seeds, fertilizer, equipment…'**
  String get suppliersSearchHint;

  /// No description provided for @suppliersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get suppliersAll;

  /// No description provided for @suppliersErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load suppliers. Please try again.'**
  String get suppliersErrorLoad;

  /// No description provided for @suppliersNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No supplier listings yet'**
  String get suppliersNoneYet;

  /// No description provided for @suppliersNoneYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, or register your business to list here.'**
  String get suppliersNoneYetMessage;

  /// No description provided for @suppliersPriceLine.
  ///
  /// In en, this message translates to:
  /// **'KSh {price}'**
  String suppliersPriceLine(String price);

  /// No description provided for @listingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listingTitle;

  /// No description provided for @listingErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this listing.'**
  String get listingErrorLoad;

  /// No description provided for @listingNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available.'**
  String get listingNoLongerAvailable;

  /// No description provided for @listingNotHarvestedBanner.
  ///
  /// In en, this message translates to:
  /// **'This crop has not yet been harvested. Estimated quantity may change at harvest.'**
  String get listingNotHarvestedBanner;

  /// No description provided for @listingExpectedHarvest.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest'**
  String get listingExpectedHarvest;

  /// No description provided for @listingHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get listingHarvested;

  /// No description provided for @listingDateTbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get listingDateTbd;

  /// No description provided for @listingDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get listingDateUnknown;

  /// No description provided for @listingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get listingLocation;

  /// No description provided for @listingFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get listingFarmer;

  /// No description provided for @listingBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get listingBatch;

  /// No description provided for @listingStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get listingStatus;

  /// No description provided for @listingTraceThisBatch.
  ///
  /// In en, this message translates to:
  /// **'Trace This Batch'**
  String get listingTraceThisBatch;

  /// No description provided for @listingFollowingThis.
  ///
  /// In en, this message translates to:
  /// **'You\'re following this'**
  String get listingFollowingThis;

  /// No description provided for @listingNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get listingNotifyMe;

  /// No description provided for @listingSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold Out'**
  String get listingSoldOut;

  /// No description provided for @listingRequestProduce.
  ///
  /// In en, this message translates to:
  /// **'Request Produce'**
  String get listingRequestProduce;

  /// No description provided for @listingPaymentDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Payment and delivery arrangements are handled directly between the buyer and seller.'**
  String get listingPaymentDisclaimer;

  /// No description provided for @requestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Produce'**
  String get requestTitle;

  /// No description provided for @requestQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String requestQuantityLabel(String unit);

  /// No description provided for @requestQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get requestQuantityHint;

  /// No description provided for @requestIntendedUse.
  ///
  /// In en, this message translates to:
  /// **'Intended use'**
  String get requestIntendedUse;

  /// No description provided for @requestFulfilmentPreference.
  ///
  /// In en, this message translates to:
  /// **'Fulfilment preference'**
  String get requestFulfilmentPreference;

  /// No description provided for @requestPreferredDate.
  ///
  /// In en, this message translates to:
  /// **'Preferred date (optional)'**
  String get requestPreferredDate;

  /// No description provided for @requestChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get requestChooseDate;

  /// No description provided for @requestMessage.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get requestMessage;

  /// No description provided for @requestMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the farmer should know'**
  String get requestMessageHint;

  /// No description provided for @requestSend.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get requestSend;

  /// No description provided for @requestErrorInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity.'**
  String get requestErrorInvalidQuantity;

  /// No description provided for @requestErrorQuantityTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Requested quantity is greater than the available quantity.'**
  String get requestErrorQuantityTooHigh;

  /// No description provided for @requestSentToFarmer.
  ///
  /// In en, this message translates to:
  /// **'Request sent to the farmer.'**
  String get requestSentToFarmer;

  /// No description provided for @requestErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String requestErrorGeneric(String error);

  /// No description provided for @farmerMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'My Marketplace'**
  String get farmerMarketplaceTitle;

  /// No description provided for @farmerMarketplaceMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get farmerMarketplaceMyListings;

  /// No description provided for @farmerMarketplaceRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get farmerMarketplaceRequests;

  /// No description provided for @farmerMarketplaceErrorListings.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your listings.'**
  String get farmerMarketplaceErrorListings;

  /// No description provided for @farmerMarketplaceNoListings.
  ///
  /// In en, this message translates to:
  /// **'No marketplace listings yet'**
  String get farmerMarketplaceNoListings;

  /// No description provided for @farmerMarketplaceNoListingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Publish a harvest from Log Harvest to see it here.'**
  String get farmerMarketplaceNoListingsMessage;

  /// No description provided for @farmerMarketplaceErrorRequests.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your requests.'**
  String get farmerMarketplaceErrorRequests;

  /// No description provided for @farmerMarketplaceNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get farmerMarketplaceNoRequests;

  /// No description provided for @farmerMarketplaceNoRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Buyer requests on your listings will show up here.'**
  String get farmerMarketplaceNoRequestsMessage;

  /// No description provided for @farmerMarketplaceRemaining.
  ///
  /// In en, this message translates to:
  /// **'{available}/{total} {unit} remaining'**
  String farmerMarketplaceRemaining(
      String available, String total, String unit);

  /// No description provided for @requestBuyerQuantity.
  ///
  /// In en, this message translates to:
  /// **'{name} · {qty} {unit}'**
  String requestBuyerQuantity(String name, String qty, String unit);

  /// No description provided for @requestPreferredLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred: {date}'**
  String requestPreferredLabel(String date);

  /// No description provided for @commonMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get commonMessage;

  /// No description provided for @commonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonDecline;

  /// No description provided for @commonAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get commonAccept;

  /// No description provided for @commonMarkFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Mark Fulfilled'**
  String get commonMarkFulfilled;

  /// No description provided for @supplierListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Product'**
  String get supplierListingTitle;

  /// No description provided for @supplierListingErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this listing.'**
  String get supplierListingErrorLoad;

  /// No description provided for @supplierListingNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available.'**
  String get supplierListingNoLongerAvailable;

  /// No description provided for @supplierListingRequestProduct.
  ///
  /// In en, this message translates to:
  /// **'Request Product'**
  String get supplierListingRequestProduct;

  /// No description provided for @supplierListingPaymentDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Payment and delivery arrangements are handled directly between you and the supplier.'**
  String get supplierListingPaymentDisclaimer;

  /// No description provided for @supplierRequestQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get supplierRequestQuantity;

  /// No description provided for @supplierRequestUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get supplierRequestUnit;

  /// No description provided for @supplierRequestUnitHint.
  ///
  /// In en, this message translates to:
  /// **'bags'**
  String get supplierRequestUnitHint;

  /// No description provided for @supplierRequestMessageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Need fertiliser suitable for spinach'**
  String get supplierRequestMessageHint;

  /// No description provided for @supplierRequestSupplierUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This supplier is no longer available.'**
  String get supplierRequestSupplierUnavailable;

  /// No description provided for @supplierRequestSentToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Request sent to the supplier.'**
  String get supplierRequestSentToSupplier;

  /// No description provided for @supplierRequestDefaultUnit.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get supplierRequestDefaultUnit;

  /// No description provided for @supplierProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Profile'**
  String get supplierProfileTitle;

  /// No description provided for @supplierProfileErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this supplier.'**
  String get supplierProfileErrorLoad;

  /// No description provided for @supplierProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This supplier is no longer available.'**
  String get supplierProfileUnavailable;

  /// No description provided for @supplierProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified Supplier'**
  String get supplierProfileVerified;

  /// No description provided for @supplierProfileCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supplierProfileCategory;

  /// No description provided for @supplierProfileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get supplierProfileLocation;

  /// No description provided for @supplierProfileProductsServices.
  ///
  /// In en, this message translates to:
  /// **'Products & Services'**
  String get supplierProfileProductsServices;

  /// No description provided for @supplierProfileErrorListings.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this supplier\'s listings.'**
  String get supplierProfileErrorListings;

  /// No description provided for @supplierProfileNoActiveListings.
  ///
  /// In en, this message translates to:
  /// **'No active listings right now.'**
  String get supplierProfileNoActiveListings;

  /// No description provided for @mySupplierBecomeSupplier.
  ///
  /// In en, this message translates to:
  /// **'Become a Supplier'**
  String get mySupplierBecomeSupplier;

  /// No description provided for @mySupplierIntro.
  ///
  /// In en, this message translates to:
  /// **'List seeds, fertiliser, equipment or services to farmers on GreenTrack.'**
  String get mySupplierIntro;

  /// No description provided for @mySupplierBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get mySupplierBusinessName;

  /// No description provided for @mySupplierGeneralLocation.
  ///
  /// In en, this message translates to:
  /// **'General location'**
  String get mySupplierGeneralLocation;

  /// No description provided for @mySupplierDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mySupplierDescription;

  /// No description provided for @mySupplierContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone (optional)'**
  String get mySupplierContactPhone;

  /// No description provided for @mySupplierContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email (optional)'**
  String get mySupplierContactEmail;

  /// No description provided for @mySupplierRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register as Supplier'**
  String get mySupplierRegisterButton;

  /// No description provided for @mySupplierPendingNotice.
  ///
  /// In en, this message translates to:
  /// **'New supplier accounts are reviewed before the \"Verified Supplier\" badge appears. You can still list products while pending review.'**
  String get mySupplierPendingNotice;

  /// No description provided for @mySupplierErrorRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Business name and location are required.'**
  String get mySupplierErrorRequiredFields;

  /// No description provided for @marketplaceTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitleShort;

  /// No description provided for @mySupplierMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get mySupplierMyListings;

  /// No description provided for @mySupplierRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get mySupplierRequests;

  /// No description provided for @mySupplierAddListing.
  ///
  /// In en, this message translates to:
  /// **'Add Listing'**
  String get mySupplierAddListing;

  /// No description provided for @mySupplierNoListings.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get mySupplierNoListings;

  /// No description provided for @mySupplierNoListingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first product or service above.'**
  String get mySupplierNoListingsMessage;

  /// No description provided for @mySupplierNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get mySupplierNoRequests;

  /// No description provided for @mySupplierNoRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Farmer requests for your products will show up here.'**
  String get mySupplierNoRequestsMessage;

  /// No description provided for @mySupplierRejectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your supplier account was not approved. Contact support for details.'**
  String get mySupplierRejectedNotice;

  /// No description provided for @mySupplierPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'Your supplier account is pending verification. Listings are live, but the \"Verified\" badge appears once approved.'**
  String get mySupplierPendingBanner;

  /// No description provided for @mySupplierActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get mySupplierActive;

  /// No description provided for @mySupplierPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mySupplierPaused;

  /// No description provided for @commonPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get commonPause;

  /// No description provided for @commonResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get commonResume;

  /// No description provided for @mySupplierProductName.
  ///
  /// In en, this message translates to:
  /// **'Product/service name'**
  String get mySupplierProductName;

  /// No description provided for @mySupplierPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get mySupplierPrice;

  /// No description provided for @mySupplierUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get mySupplierUnit;

  /// No description provided for @mySupplierUnitHint.
  ///
  /// In en, this message translates to:
  /// **'bag, litre'**
  String get mySupplierUnitHint;

  /// No description provided for @mySupplierPublishListing.
  ///
  /// In en, this message translates to:
  /// **'Publish Listing'**
  String get mySupplierPublishListing;

  /// No description provided for @mySupplierErrorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a product/service name.'**
  String get mySupplierErrorEnterName;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your messages.'**
  String get messagesErrorLoad;

  /// No description provided for @messagesNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesNoConversations;

  /// No description provided for @messagesNoConversationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Chats open once you request produce or a supplier product.'**
  String get messagesNoConversationsMessage;

  /// No description provided for @messagesNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get messagesNoMessagesYet;

  /// No description provided for @messagesConversationFallback.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get messagesConversationFallback;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationTitle;

  /// No description provided for @conversationErrorOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open this conversation.'**
  String get conversationErrorOpen;

  /// No description provided for @conversationErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this conversation.'**
  String get conversationErrorLoad;

  /// No description provided for @conversationRequestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get conversationRequestUnavailable;

  /// No description provided for @conversationRequestFallback.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get conversationRequestFallback;

  /// No description provided for @conversationErrorLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load messages.'**
  String get conversationErrorLoadMessages;

  /// No description provided for @conversationSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello — this is where you and the other party talk.'**
  String get conversationSayHello;

  /// No description provided for @conversationHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get conversationHint;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequestsTitle;

  /// No description provided for @myRequestsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get myRequestsNoneYet;

  /// No description provided for @myRequestsNoneYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Requests you send for produce or supplier products show up here.'**
  String get myRequestsNoneYetMessage;

  /// No description provided for @adminAccessRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Requests'**
  String get adminAccessRequestsTitle;

  /// No description provided for @adminRoleRequestsTab.
  ///
  /// In en, this message translates to:
  /// **'Role Requests'**
  String get adminRoleRequestsTab;

  /// No description provided for @adminSuppliersTab.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get adminSuppliersTab;

  /// No description provided for @adminErrorVerifyAccess.
  ///
  /// In en, this message translates to:
  /// **'Could not verify admin access: {error}'**
  String adminErrorVerifyAccess(String error);

  /// No description provided for @adminNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Not Authorized'**
  String get adminNotAuthorized;

  /// No description provided for @adminNoAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'This account doesn\'t have admin access.'**
  String get adminNoAdminAccess;

  /// No description provided for @adminErrorLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests: {error}'**
  String adminErrorLoadRequests(String error);

  /// No description provided for @adminNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get adminNoPendingRequests;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved'**
  String adminApproved(String name);

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'{name} rejected'**
  String adminRejected(String name);

  /// No description provided for @adminErrorSaveDecision.
  ///
  /// In en, this message translates to:
  /// **'Could not save decision: {error}'**
  String adminErrorSaveDecision(String error);

  /// No description provided for @commonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get commonReject;

  /// No description provided for @commonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApprove;

  /// No description provided for @commonVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get commonVerify;

  /// No description provided for @adminErrorLoadSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Could not load suppliers: {error}'**
  String adminErrorLoadSuppliers(String error);

  /// No description provided for @adminNoSuppliersAwaiting.
  ///
  /// In en, this message translates to:
  /// **'No suppliers awaiting verification'**
  String get adminNoSuppliersAwaiting;

  /// No description provided for @adminSupplierVerified.
  ///
  /// In en, this message translates to:
  /// **'{name} verified'**
  String adminSupplierVerified(String name);

  /// No description provided for @consumerGreetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get consumerGreetingFallbackName;

  /// No description provided for @consumerGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get consumerGoodMorning;

  /// No description provided for @consumerGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get consumerGoodAfternoon;

  /// No description provided for @consumerGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get consumerGoodEvening;

  /// No description provided for @consumerPlateTagline.
  ///
  /// In en, this message translates to:
  /// **'Know exactly what\'s on your plate 🍽️'**
  String get consumerPlateTagline;

  /// No description provided for @statScans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get statScans;

  /// No description provided for @statTotalTraced.
  ///
  /// In en, this message translates to:
  /// **'Total traced'**
  String get statTotalTraced;

  /// No description provided for @statOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get statOrganic;

  /// No description provided for @statVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statVerified;

  /// No description provided for @statMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get statMeals;

  /// No description provided for @statTraced.
  ///
  /// In en, this message translates to:
  /// **'Traced'**
  String get statTraced;

  /// No description provided for @dashboardMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get dashboardMarketplaceTitle;

  /// No description provided for @dashboardMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh produce & upcoming harvests'**
  String get dashboardMarketplaceSubtitle;

  /// No description provided for @dashboardMarketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse, follow a harvest, or request produce.'**
  String get dashboardMarketplaceDescription;

  /// No description provided for @consumerRecentScans.
  ///
  /// In en, this message translates to:
  /// **'Recent Scans'**
  String get consumerRecentScans;

  /// No description provided for @consumerScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get consumerScanQrCode;

  /// No description provided for @consumerScanQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Product packaging or restaurant menu'**
  String get consumerScanQrSubtitle;

  /// No description provided for @consumerNoScansYet.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get consumerNoScansYet;

  /// No description provided for @consumerNoScansMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a product\'s QR code and it\'ll show up here — nothing\nis shown until you actually scan something.'**
  String get consumerNoScansMessage;

  /// No description provided for @consumerScanFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan your first product'**
  String get consumerScanFirstProduct;

  /// No description provided for @consumerOrganicBadge.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get consumerOrganicBadge;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap your photo on the profile page to change it'**
  String get settingsEditProfileSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsNoEmailOnFile.
  ///
  /// In en, this message translates to:
  /// **'No email on file'**
  String get settingsNoEmailOnFile;

  /// No description provided for @settingsSendResetLinkTo.
  ///
  /// In en, this message translates to:
  /// **'Send a reset link to {email}'**
  String settingsSendResetLinkTo(String email);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get settingsNotificationCenter;

  /// No description provided for @settingsNotificationCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Batch alerts, PHI reminders, and updates'**
  String get settingsNotificationCenterSubtitle;

  /// No description provided for @settingsPrivacySupport.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Support'**
  String get settingsPrivacySupport;

  /// No description provided for @settingsPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacySecurity;

  /// No description provided for @settingsPrivacySecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data usage, permissions, manage crops'**
  String get settingsPrivacySecuritySubtitle;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs and contact'**
  String get settingsHelpSupportSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get settingsAdmin;

  /// No description provided for @settingsAccessRequests.
  ///
  /// In en, this message translates to:
  /// **'Access Requests'**
  String get settingsAccessRequests;

  /// No description provided for @settingsAccessRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending supply-chain sign-ups'**
  String get settingsAccessRequestsSubtitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsVersionLabel;

  /// No description provided for @settingsNoEmailSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No email on file for this account'**
  String get settingsNoEmailSnackbar;

  /// No description provided for @settingsResetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Please try again.'**
  String get settingsResetEmailFailed;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your account.'**
  String get settingsSignOutConfirmBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTagline => 'Kukuza Ulaji wa Kuwajibika';

  @override
  String get commonEmail => 'Barua pepe';

  @override
  String get commonPassword => 'Nenosiri';

  @override
  String get commonFullName => 'Jina Kamili';

  @override
  String get commonCancel => 'Ghairi';

  @override
  String get commonSave => 'Hifadhi';

  @override
  String get commonSignIn => 'Ingia';

  @override
  String get commonSignUp => 'Jisajili';

  @override
  String get loginCreateAccountButton => 'Fungua Akaunti';

  @override
  String get loginWelcomeBack => 'Karibu tena.';

  @override
  String get loginCreateAccount => 'Fungua akaunti.';

  @override
  String get loginSignInSubtitle => 'Ingia kwenye akaunti yako';

  @override
  String get loginJoinSubtitle => 'Jiunge na mtandao wa GreenTrack';

  @override
  String get loginFullNameHint => 'Mwangi Kamau';

  @override
  String get loginForgotPassword => 'Umesahau nenosiri?';

  @override
  String get loginOrContinueWith => 'au endelea na';

  @override
  String get loginContinueWithGoogle => 'Endelea na Google';

  @override
  String get loginNoAccount => 'Una akaunti tayari? ';

  @override
  String get loginNoAccountYet => 'Huna akaunti? ';

  @override
  String get loginEmailHint => 'wewe@barua-pepe.com';

  @override
  String get errorEnterEmailFirst =>
      'Weka barua pepe yako hapo juu kwanza, kisha ubofye \"Umesahau nenosiri?\"';

  @override
  String get loginQuickAccessDev => 'UFIKIAJI WA HARAKA (DEV)';

  @override
  String get roleFarmer => 'Mkulima';

  @override
  String get roleChef => 'Mpishi';

  @override
  String get roleConsumer => 'Mtumiaji';

  @override
  String get roleAggregator => 'Mkusanyaji';

  @override
  String get roleTransporter => 'Msafirishaji';

  @override
  String get roleDistributor => 'Msambazaji';

  @override
  String get errorEnterEmailPassword =>
      'Tafadhali weka barua pepe na nenosiri lako.';

  @override
  String get errorEnterName => 'Tafadhali weka jina lako.';

  @override
  String get errorInvalidEmail => 'Tafadhali weka anwani sahihi ya barua pepe.';

  @override
  String get errorNoAccountFound =>
      'Hakuna akaunti iliyopatikana kwa barua pepe hii.';

  @override
  String get errorIncorrectEmailPassword => 'Barua pepe au nenosiri si sahihi.';

  @override
  String get errorIncorrectEmailPasswordGoogleHint =>
      'Barua pepe au nenosiri si sahihi. Ikiwa awali ulijisajili kwa Google, tumia \"Endelea na Google\" hapa chini badala yake.';

  @override
  String get errorEmailSignInNotEnabled =>
      'Kuingia kwa barua pepe/nenosiri hakujawezeshwa kwa programu hii bado. Wasiliana na msimamizi wa programu, au jaribu \"Endelea na Google\" hapa chini.';

  @override
  String get errorAccountExists => 'Akaunti yenye barua pepe hii tayari ipo.';

  @override
  String get errorWeakPassword =>
      'Nenosiri linapaswa kuwa na herufi angalau 6.';

  @override
  String get errorNoInternet => 'Hakuna muunganisho wa intaneti.';

  @override
  String get errorTooManyRequests =>
      'Majaribio mengi sana. Tafadhali subiri kidogo kisha ujaribu tena.';

  @override
  String get errorSignInTimeout =>
      'Muda wa kuingia umeisha — angalia muunganisho wako (programu ya kuzuia matangazo inaweza pia kuzuia hili) kisha ujaribu tena.';

  @override
  String get errorSignInFailed => 'Imeshindwa kuingia. Tafadhali jaribu tena.';

  @override
  String get errorGoogleSignInFailed =>
      'Imeshindwa kuingia na Google. Tafadhali jaribu tena.';

  @override
  String get errorGoogleSignInNotConfigured =>
      'Kuingia na Google hakujawekwa kwa toleo hili la programu (SHA-1 haipo kwenye Firebase). Wasiliana na usaidizi.';

  @override
  String passwordResetLinkSent(String email) {
    return 'Kiungo cha kuweka upya nenosiri kimetumwa kwa $email';
  }

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get settingsLanguage => 'Lugha';

  @override
  String get settingsLanguageEnglish => 'Kiingereza';

  @override
  String get settingsLanguageSwahili => 'Kiswahili';

  @override
  String get marketplaceTitle => 'Soko';

  @override
  String get marketplaceMyRequests => 'Maombi Yangu';

  @override
  String get marketplaceMessages => 'Ujumbe';

  @override
  String get marketplaceTagline =>
      'Pata mazao mapya, mavuno yajayo na wasambazaji wa kilimo wanaoaminika.';

  @override
  String get marketplaceSearchHint => 'Tafuta mazao, mfano Mchicha';

  @override
  String get marketplaceFilters => 'Vichujio';

  @override
  String get marketplaceViewAll => 'Zote';

  @override
  String get marketplaceViewAvailableNow => 'Zilizopo Sasa';

  @override
  String get marketplaceViewHarvestingSoon => 'Zinakaribia Kuvunwa';

  @override
  String get marketplaceTraceABatch => 'Fuatilia Mfuko';

  @override
  String get marketplaceFreshProduce => 'Mazao Mapya';

  @override
  String get marketplaceErrorLoadListings =>
      'Imeshindwa kupakia orodha za soko. Tafadhali jaribu tena.';

  @override
  String get marketplaceNoProduceMatch =>
      'Hakuna mazao yanayolingana na utafutaji wako';

  @override
  String get marketplaceNoProduceAvailable => 'Hakuna mazao yaliyopo sasa hivi';

  @override
  String get marketplaceTryWideningFilters =>
      'Jaribu kupunguza vichujio vyako.';

  @override
  String get marketplaceCheckBackSoon =>
      'Angalia tena hivi karibuni, au fuatilia mavuno yajayo hapa chini.';

  @override
  String get marketplaceErrorLoadHarvests =>
      'Imeshindwa kupakia mavuno yajayo. Tafadhali jaribu tena.';

  @override
  String get marketplaceNoHarvestsMatch =>
      'Hakuna mavuno yajayo yanayolingana na utafutaji wako';

  @override
  String get marketplaceNoHarvestsYet => 'Hakuna mavuno yajayo bado.';

  @override
  String get marketplaceAgriSuppliers => 'Wasambazaji wa Kilimo';

  @override
  String get marketplaceViewAllLink => 'Ona zote';

  @override
  String get marketplaceSuppliersBlurb => 'Mbegu, mbolea, vifaa na zaidi';

  @override
  String get marketplaceFilterProduce => 'Chuja Mazao';

  @override
  String get marketplaceLocation => 'Mahali';

  @override
  String get marketplaceLocationHint => 'mfano Nakuru';

  @override
  String get marketplaceMinQuantity => 'Kiwango cha chini';

  @override
  String get marketplaceMaxPrice => 'Bei ya juu zaidi (KSh, si lazima)';

  @override
  String get commonClear => 'Futa';

  @override
  String get commonApply => 'Tumia';

  @override
  String marketplaceFreshCropName(String crop) {
    return '$crop Mpya';
  }

  @override
  String marketplaceEstQuantity(String qty, String unit) {
    return 'Makadirio $qty $unit';
  }

  @override
  String marketplaceExpectedDate(String date) {
    return ' · Inatarajiwa $date';
  }

  @override
  String marketplaceAvailableQuantity(String qty, String unit) {
    return '$qty $unit zinapatikana';
  }

  @override
  String marketplaceHarvestedDate(String date) {
    return ' · Imevunwa $date';
  }

  @override
  String marketplacePriceLine(String price, String unit) {
    return 'KSh $price/$unit';
  }

  @override
  String get suppliersTitle => 'Wasambazaji wa Kilimo';

  @override
  String get suppliersSellHere => 'Uza hapa';

  @override
  String get suppliersSearchHint => 'Tafuta mbegu, mbolea, vifaa…';

  @override
  String get suppliersAll => 'Zote';

  @override
  String get suppliersErrorLoad =>
      'Imeshindwa kupakia wasambazaji. Tafadhali jaribu tena.';

  @override
  String get suppliersNoneYet => 'Hakuna orodha za wasambazaji bado';

  @override
  String get suppliersNoneYetMessage =>
      'Angalia tena hivi karibuni, au sajili biashara yako ili kuorodhesha hapa.';

  @override
  String suppliersPriceLine(String price) {
    return 'KSh $price';
  }

  @override
  String get listingTitle => 'Orodha';

  @override
  String get listingErrorLoad => 'Imeshindwa kupakia orodha hii.';

  @override
  String get listingNoLongerAvailable => 'Orodha hii haipatikani tena.';

  @override
  String get listingNotHarvestedBanner =>
      'Zao hili halijavunwa bado. Kiwango kilichokadiriwa kinaweza kubadilika wakati wa mavuno.';

  @override
  String get listingExpectedHarvest => 'Mavuno yanayotarajiwa';

  @override
  String get listingHarvested => 'Imevunwa';

  @override
  String get listingDateTbd => 'Bado';

  @override
  String get listingDateUnknown => 'Haijulikani';

  @override
  String get listingLocation => 'Mahali';

  @override
  String get listingFarmer => 'Mkulima';

  @override
  String get listingBatch => 'Mfuko';

  @override
  String get listingStatus => 'Hali';

  @override
  String get listingTraceThisBatch => 'Fuatilia Mfuko Huu';

  @override
  String get listingFollowingThis => 'Unafuatilia hii';

  @override
  String get listingNotifyMe => 'Nijulishe';

  @override
  String get listingSoldOut => 'Zimeisha';

  @override
  String get listingRequestProduce => 'Omba Mazao';

  @override
  String get listingPaymentDisclaimer =>
      'Malipo na mipango ya uwasilishaji hushughulikiwa moja kwa moja kati ya mnunuzi na muuzaji.';

  @override
  String get requestTitle => 'Omba Mazao';

  @override
  String requestQuantityLabel(String unit) {
    return 'Kiwango ($unit)';
  }

  @override
  String get requestQuantityHint => 'mfano 10';

  @override
  String get requestIntendedUse => 'Matumizi yaliyokusudiwa';

  @override
  String get requestFulfilmentPreference => 'Upendeleo wa uwasilishaji';

  @override
  String get requestPreferredDate => 'Tarehe unayopendelea (si lazima)';

  @override
  String get requestChooseDate => 'Chagua tarehe';

  @override
  String get requestMessage => 'Ujumbe (si lazima)';

  @override
  String get requestMessageHint => 'Chochote mkulima anapaswa kujua';

  @override
  String get requestSend => 'Tuma Ombi';

  @override
  String get requestErrorInvalidQuantity => 'Weka kiwango sahihi.';

  @override
  String get requestErrorQuantityTooHigh =>
      'Kiwango ulichoomba ni kikubwa kuliko kilichopo.';

  @override
  String get requestSentToFarmer => 'Ombi limetumwa kwa mkulima.';

  @override
  String requestErrorGeneric(String error) {
    return 'Hitilafu: $error';
  }

  @override
  String get farmerMarketplaceTitle => 'Soko Langu';

  @override
  String get farmerMarketplaceMyListings => 'Orodha Zangu';

  @override
  String get farmerMarketplaceRequests => 'Maombi';

  @override
  String get farmerMarketplaceErrorListings =>
      'Imeshindwa kupakia orodha zako.';

  @override
  String get farmerMarketplaceNoListings => 'Hakuna orodha za soko bado';

  @override
  String get farmerMarketplaceNoListingsMessage =>
      'Chapisha mavuno kutoka Rekodi Mavuno ili kuyaona hapa.';

  @override
  String get farmerMarketplaceErrorRequests =>
      'Imeshindwa kupakia maombi yako.';

  @override
  String get farmerMarketplaceNoRequests => 'Hakuna maombi bado';

  @override
  String get farmerMarketplaceNoRequestsMessage =>
      'Maombi ya wanunuzi kwenye orodha zako yataonekana hapa.';

  @override
  String farmerMarketplaceRemaining(
      String available, String total, String unit) {
    return '$available/$total $unit zimebaki';
  }

  @override
  String requestBuyerQuantity(String name, String qty, String unit) {
    return '$name · $qty $unit';
  }

  @override
  String requestPreferredLabel(String date) {
    return 'Inapendelewa: $date';
  }

  @override
  String get commonMessage => 'Ujumbe';

  @override
  String get commonDecline => 'Kataa';

  @override
  String get commonAccept => 'Kubali';

  @override
  String get commonMarkFulfilled => 'Weka Alama Imetimizwa';

  @override
  String get supplierListingTitle => 'Bidhaa ya Msambazaji';

  @override
  String get supplierListingErrorLoad => 'Imeshindwa kupakia orodha hii.';

  @override
  String get supplierListingNoLongerAvailable => 'Orodha hii haipatikani tena.';

  @override
  String get supplierListingRequestProduct => 'Omba Bidhaa';

  @override
  String get supplierListingPaymentDisclaimer =>
      'Malipo na mipango ya uwasilishaji hushughulikiwa moja kwa moja kati yako na msambazaji.';

  @override
  String get supplierRequestQuantity => 'Kiwango';

  @override
  String get supplierRequestUnit => 'Kipimo';

  @override
  String get supplierRequestUnitHint => 'magunia';

  @override
  String get supplierRequestMessageHint =>
      'mfano Nahitaji mbolea inayofaa mchicha';

  @override
  String get supplierRequestSupplierUnavailable =>
      'Msambazaji huyu hapatikani tena.';

  @override
  String get supplierRequestSentToSupplier => 'Ombi limetumwa kwa msambazaji.';

  @override
  String get supplierRequestDefaultUnit => 'vipande';

  @override
  String get supplierProfileTitle => 'Wasifu wa Msambazaji';

  @override
  String get supplierProfileErrorLoad => 'Imeshindwa kupakia msambazaji huyu.';

  @override
  String get supplierProfileUnavailable => 'Msambazaji huyu hapatikani tena.';

  @override
  String get supplierProfileVerified => 'Msambazaji Aliyethibitishwa';

  @override
  String get supplierProfileCategory => 'Aina';

  @override
  String get supplierProfileLocation => 'Mahali';

  @override
  String get supplierProfileProductsServices => 'Bidhaa na Huduma';

  @override
  String get supplierProfileErrorListings =>
      'Imeshindwa kupakia orodha za msambazaji huyu.';

  @override
  String get supplierProfileNoActiveListings =>
      'Hakuna orodha zinazoendelea kwa sasa.';

  @override
  String get mySupplierBecomeSupplier => 'Kuwa Msambazaji';

  @override
  String get mySupplierIntro =>
      'Orodhesha mbegu, mbolea, vifaa au huduma kwa wakulima kwenye GreenTrack.';

  @override
  String get mySupplierBusinessName => 'Jina la biashara';

  @override
  String get mySupplierGeneralLocation => 'Mahali kwa ujumla';

  @override
  String get mySupplierDescription => 'Maelezo';

  @override
  String get mySupplierContactPhone => 'Simu ya mawasiliano (si lazima)';

  @override
  String get mySupplierContactEmail => 'Barua pepe ya mawasiliano (si lazima)';

  @override
  String get mySupplierRegisterButton => 'Jisajili kama Msambazaji';

  @override
  String get mySupplierPendingNotice =>
      'Akaunti mpya za wasambazaji hukaguliwa kabla alama ya \"Msambazaji Aliyethibitishwa\" haijaonekana. Bado unaweza kuorodhesha bidhaa wakati wa ukaguzi.';

  @override
  String get mySupplierErrorRequiredFields =>
      'Jina la biashara na mahali vinahitajika.';

  @override
  String get marketplaceTitleShort => 'Soko';

  @override
  String get mySupplierMyListings => 'Orodha Zangu';

  @override
  String get mySupplierRequests => 'Maombi';

  @override
  String get mySupplierAddListing => 'Ongeza Orodha';

  @override
  String get mySupplierNoListings => 'Hakuna orodha bado';

  @override
  String get mySupplierNoListingsMessage =>
      'Ongeza bidhaa au huduma yako ya kwanza hapo juu.';

  @override
  String get mySupplierNoRequests => 'Hakuna maombi bado';

  @override
  String get mySupplierNoRequestsMessage =>
      'Maombi ya wakulima kwa bidhaa zako yataonekana hapa.';

  @override
  String get mySupplierRejectedNotice =>
      'Akaunti yako ya msambazaji haikuidhinishwa. Wasiliana na usaidizi kwa maelezo zaidi.';

  @override
  String get mySupplierPendingBanner =>
      'Akaunti yako ya msambazaji inasubiri uthibitisho. Orodha zako zinaonekana, lakini alama ya \"Imethibitishwa\" itaonekana baada ya kuidhinishwa.';

  @override
  String get mySupplierActive => 'Inaendelea';

  @override
  String get mySupplierPaused => 'Imesimamishwa';

  @override
  String get commonPause => 'Simamisha';

  @override
  String get commonResume => 'Endelea';

  @override
  String get mySupplierProductName => 'Jina la bidhaa/huduma';

  @override
  String get mySupplierPrice => 'Bei (si lazima)';

  @override
  String get mySupplierUnit => 'Kipimo (si lazima)';

  @override
  String get mySupplierUnitHint => 'gunia, lita';

  @override
  String get mySupplierPublishListing => 'Chapisha Orodha';

  @override
  String get mySupplierErrorEnterName => 'Weka jina la bidhaa/huduma.';

  @override
  String get messagesTitle => 'Ujumbe';

  @override
  String get messagesErrorLoad => 'Imeshindwa kupakia ujumbe wako.';

  @override
  String get messagesNoConversations => 'Hakuna mazungumzo bado';

  @override
  String get messagesNoConversationsMessage =>
      'Mazungumzo hufunguka mara tu unapoomba mazao au bidhaa ya msambazaji.';

  @override
  String get messagesNoMessagesYet => 'Hakuna ujumbe bado';

  @override
  String get messagesConversationFallback => 'Mazungumzo';

  @override
  String get conversationTitle => 'Mazungumzo';

  @override
  String get conversationErrorOpen => 'Imeshindwa kufungua mazungumzo haya.';

  @override
  String get conversationErrorLoad => 'Imeshindwa kupakia mazungumzo haya.';

  @override
  String get conversationRequestUnavailable => 'Ombi hili halipatikani tena.';

  @override
  String get conversationRequestFallback => 'Ombi';

  @override
  String get conversationErrorLoadMessages => 'Imeshindwa kupakia ujumbe.';

  @override
  String get conversationSayHello =>
      'Sema hujambo — hapa ndipo wewe na upande mwingine mnazungumza.';

  @override
  String get conversationHint => 'Ujumbe…';

  @override
  String get myRequestsTitle => 'Maombi Yangu';

  @override
  String get myRequestsNoneYet => 'Hakuna maombi bado';

  @override
  String get myRequestsNoneYetMessage =>
      'Maombi unayotuma kwa mazao au bidhaa za wasambazaji yataonekana hapa.';

  @override
  String get adminAccessRequestsTitle => 'Maombi ya Ufikiaji';

  @override
  String get adminRoleRequestsTab => 'Maombi ya Nafasi';

  @override
  String get adminSuppliersTab => 'Wasambazaji';

  @override
  String adminErrorVerifyAccess(String error) {
    return 'Imeshindwa kuthibitisha ufikiaji wa msimamizi: $error';
  }

  @override
  String get adminNotAuthorized => 'Hairuhusiwi';

  @override
  String get adminNoAdminAccess => 'Akaunti hii haina ufikiaji wa msimamizi.';

  @override
  String adminErrorLoadRequests(String error) {
    return 'Imeshindwa kupakia maombi: $error';
  }

  @override
  String get adminNoPendingRequests => 'Hakuna maombi yanayosubiri';

  @override
  String adminApproved(String name) {
    return '$name ameidhinishwa';
  }

  @override
  String adminRejected(String name) {
    return '$name amekataliwa';
  }

  @override
  String adminErrorSaveDecision(String error) {
    return 'Imeshindwa kuhifadhi uamuzi: $error';
  }

  @override
  String get commonReject => 'Kataa';

  @override
  String get commonApprove => 'Idhinisha';

  @override
  String get commonVerify => 'Thibitisha';

  @override
  String adminErrorLoadSuppliers(String error) {
    return 'Imeshindwa kupakia wasambazaji: $error';
  }

  @override
  String get adminNoSuppliersAwaiting =>
      'Hakuna wasambazaji wanaosubiri uthibitisho';

  @override
  String adminSupplierVerified(String name) {
    return '$name amethibitishwa';
  }

  @override
  String get consumerGreetingFallbackName => 'wewe';

  @override
  String get consumerGoodMorning => 'Habari za Asubuhi';

  @override
  String get consumerGoodAfternoon => 'Habari za Mchana';

  @override
  String get consumerGoodEvening => 'Habari za Jioni';

  @override
  String get consumerPlateTagline => 'Jua hasa kilicho kwenye sahani yako 🍽️';

  @override
  String get statScans => 'Skani';

  @override
  String get statTotalTraced => 'Jumla iliyofuatiliwa';

  @override
  String get statOrganic => 'Asili';

  @override
  String get statVerified => 'Imethibitishwa';

  @override
  String get statMeals => 'Milo';

  @override
  String get statTraced => 'Imefuatiliwa';

  @override
  String get dashboardMarketplaceTitle => 'Soko';

  @override
  String get dashboardMarketplaceSubtitle => 'Mazao mapya na mavuno yajayo';

  @override
  String get dashboardMarketplaceDescription =>
      'Vinjari, fuatilia mavuno, au omba mazao.';

  @override
  String get consumerRecentScans => 'Skani za Hivi Karibuni';

  @override
  String get consumerScanQrCode => 'Skani Msimbo wa QR';

  @override
  String get consumerScanQrSubtitle => 'Ufungaji wa bidhaa au menyu ya mkahawa';

  @override
  String get consumerNoScansYet => 'Hakuna skani bado';

  @override
  String get consumerNoScansMessage =>
      'Skani msimbo wa QR wa bidhaa nao utaonekana hapa — hakuna kinachoonyeshwa mpaka uskani kitu.';

  @override
  String get consumerScanFirstProduct => 'Skani bidhaa yako ya kwanza';

  @override
  String get consumerOrganicBadge => 'Asili';

  @override
  String get timeJustNow => 'Sasa hivi';

  @override
  String timeMinutesAgo(int count) {
    return 'dakika $count zilizopita';
  }

  @override
  String timeHoursAgo(int count) {
    return 'saa $count zilizopita';
  }

  @override
  String timeDaysAgo(int count) {
    return 'siku $count zilizopita';
  }

  @override
  String get settingsAppearance => 'Muonekano';

  @override
  String get settingsAccount => 'Akaunti';

  @override
  String get settingsEditProfile => 'Hariri Wasifu';

  @override
  String get settingsEditProfileSubtitle =>
      'Gusa picha yako kwenye ukurasa wa wasifu ili kuibadilisha';

  @override
  String get settingsChangePassword => 'Badilisha Nenosiri';

  @override
  String get settingsNoEmailOnFile => 'Hakuna barua pepe iliyosajiliwa';

  @override
  String settingsSendResetLinkTo(String email) {
    return 'Tuma kiungo cha kuweka upya kwa $email';
  }

  @override
  String get settingsNotifications => 'Arifa';

  @override
  String get settingsNotificationCenter => 'Kituo cha Arifa';

  @override
  String get settingsNotificationCenterSubtitle =>
      'Arifa za mfuko, vikumbusho vya PHI, na masasisho';

  @override
  String get settingsPrivacySupport => 'Faragha na Msaada';

  @override
  String get settingsPrivacySecurity => 'Faragha na Usalama';

  @override
  String get settingsPrivacySecuritySubtitle =>
      'Matumizi ya data, ruhusa, dhibiti mazao';

  @override
  String get settingsHelpSupport => 'Msaada';

  @override
  String get settingsHelpSupportSubtitle =>
      'Maswali yanayoulizwa mara kwa mara na mawasiliano';

  @override
  String get settingsAbout => 'Kuhusu';

  @override
  String get settingsTermsOfService => 'Masharti ya Huduma';

  @override
  String get settingsPrivacyPolicy => 'Sera ya Faragha';

  @override
  String get settingsAdmin => 'Msimamizi';

  @override
  String get settingsAccessRequests => 'Maombi ya Ufikiaji';

  @override
  String get settingsAccessRequestsSubtitle =>
      'Kagua usajili wa mnyororo wa ugavi unaosubiri';

  @override
  String get settingsSignOut => 'Toka';

  @override
  String get settingsVersionLabel => 'Toleo 1.0.0';

  @override
  String get settingsNoEmailSnackbar =>
      'Hakuna barua pepe iliyosajiliwa kwa akaunti hii';

  @override
  String get settingsResetEmailFailed =>
      'Imeshindwa kutuma barua pepe ya kuweka upya. Tafadhali jaribu tena.';

  @override
  String get settingsSignOutConfirmTitle => 'Toka?';

  @override
  String get settingsSignOutConfirmBody =>
      'Utahitaji kuingia tena ili kufikia akaunti yako.';
}

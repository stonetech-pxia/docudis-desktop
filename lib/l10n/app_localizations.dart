import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('es'),
    Locale('fr'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Docudis'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButton;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get forgotPasswordHint;

  /// No description provided for @sendResetEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmailButton;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get continueWithApple;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get noAccountYet;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters.'**
  String validationPasswordTooShort(int min);

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorAccountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email using a different sign-in method.'**
  String get authErrorAccountExistsWithDifferentCredential;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @homeSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String homeSignedInAs(String email);

  /// No description provided for @anonymizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get anonymizeTitle;

  /// No description provided for @inputPasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get inputPasteText;

  /// No description provided for @inputPickFile.
  ///
  /// In en, this message translates to:
  /// **'Upload a document'**
  String get inputPickFile;

  /// No description provided for @inputTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Scan a photo'**
  String get inputTakePhoto;

  /// No description provided for @photoFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoFromCamera;

  /// No description provided for @photoFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get photoFromLibrary;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Reading and anonymizing…'**
  String get processing;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing processed yet.'**
  String get historyEmpty;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected copy'**
  String get resultTitle;

  /// No description provided for @tabAnonymized.
  ///
  /// In en, this message translates to:
  /// **'Anonymized'**
  String get tabAnonymized;

  /// No description provided for @tabOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get tabOriginal;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share file'**
  String get shareFile;

  /// No description provided for @sharedImageName.
  ///
  /// In en, this message translates to:
  /// **'Anonymized image'**
  String get sharedImageName;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share text'**
  String get shareText;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get copied;

  /// No description provided for @detectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sensitive items} =1{1 sensitive item} other{{count} sensitive items}}'**
  String detectionCount(int count);

  /// No description provided for @noDetections.
  ///
  /// In en, this message translates to:
  /// **'No sensitive information was found.'**
  String get noDetections;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this record and its restore key?'**
  String get deleteRecordConfirm;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the whole history? This cannot be undone.'**
  String get deleteAllConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTitle;

  /// No description provided for @restoreHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the AI\'s reply. Labels are swapped back using the key stored on this phone.'**
  String get restoreHint;

  /// No description provided for @entityPerson.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get entityPerson;

  /// No description provided for @entityEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get entityEmail;

  /// No description provided for @entityPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get entityPhone;

  /// No description provided for @entityId.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get entityId;

  /// No description provided for @entityCard.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get entityCard;

  /// No description provided for @entityIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get entityIban;

  /// No description provided for @entityDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entityDate;

  /// No description provided for @entityAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get entityAmount;

  /// No description provided for @entityIp.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get entityIp;

  /// No description provided for @entityUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get entityUrl;

  /// No description provided for @entityAddress.
  ///
  /// In en, this message translates to:
  /// **'Address / place'**
  String get entityAddress;

  /// No description provided for @entityCompany.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get entityCompany;

  /// No description provided for @entitySecret.
  ///
  /// In en, this message translates to:
  /// **'Secret / API key'**
  String get entitySecret;

  /// No description provided for @entityCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom keyword'**
  String get entityCustom;

  /// No description provided for @entityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get entityOther;

  /// No description provided for @errorNoText.
  ///
  /// In en, this message translates to:
  /// **'No text could be read from this input.'**
  String get errorNoText;

  /// No description provided for @errorUnsupportedFile.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported yet.'**
  String get errorUnsupportedFile;

  /// No description provided for @errorProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed. Please try again.'**
  String get errorProcessingFailed;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Change what is hidden'**
  String get reviewTitle;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a label to bring the real text back. Tap a name, a number or any other text to hide it. Saved as you go.'**
  String get reviewHint;

  /// No description provided for @reviewHideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide all amounts'**
  String get reviewHideAmounts;

  /// No description provided for @reviewHideDates.
  ///
  /// In en, this message translates to:
  /// **'Hide all dates'**
  String get reviewHideDates;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Replaced with labels like [PERSON_1] so AI answers still make sense.'**
  String get reviewNote;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @resultBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing needed replacing.} =1{1 item replaced.} other{{count} items replaced.}}'**
  String resultBanner(int count);

  /// No description provided for @restoreKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore key kept on this phone'**
  String get restoreKeyTitle;

  /// No description provided for @restoreKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pair · never uploaded · delete anytime} other{{count} pairs · never uploaded · delete anytime}}'**
  String restoreKeySubtitle(int count);

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to {app}'**
  String sendTo(String app);

  /// No description provided for @aiReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'AI reply'**
  String get aiReplyLabel;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @restoredLabel.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restoredLabel;

  /// No description provided for @restoredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No labels found to restore.} =1{1 label restored.} other{{count} labels restored.}}'**
  String restoredCount(int count);

  /// No description provided for @restoreDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get restoreDocumentLabel;

  /// No description provided for @restoreMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'This reply doesn\'t fit this document'**
  String get restoreMismatchTitle;

  /// No description provided for @restoreMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'It has labels this document never used: {labels}. It is probably the reply to another document: open that one from History and restore it there.'**
  String restoreMismatchBody(String labels);

  /// No description provided for @restoreShowAnyway.
  ///
  /// In en, this message translates to:
  /// **'Show anyway'**
  String get restoreShowAnyway;

  /// No description provided for @restoreOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'This reply seems to be for another document'**
  String get restoreOtherTitle;

  /// No description provided for @restoreOtherBody.
  ///
  /// In en, this message translates to:
  /// **'Its labels and wording fit “{name}” better. Restored here, it would get this document\'s names and numbers.'**
  String restoreOtherBody(String name);

  /// No description provided for @restoreUseOther.
  ///
  /// In en, this message translates to:
  /// **'Restore with that document'**
  String get restoreUseOther;

  /// No description provided for @restoreInvented.
  ///
  /// In en, this message translates to:
  /// **'Not in this document, left as is: {labels}'**
  String restoreInvented(String labels);

  /// No description provided for @restoreShownAnyway.
  ///
  /// In en, this message translates to:
  /// **'Restored with this document\'s key, although the reply fits “{name}” better.'**
  String restoreShownAnyway(String name);

  /// No description provided for @copyRestored.
  ///
  /// In en, this message translates to:
  /// **'Copy restored text'**
  String get copyRestored;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard has no text.'**
  String get clipboardEmpty;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Protect your personal data by anonymizing it.'**
  String get homeHeadline;

  /// No description provided for @homeCaption.
  ///
  /// In en, this message translates to:
  /// **'Runs entirely on this phone. Nothing is uploaded.'**
  String get homeCaption;

  /// No description provided for @anonymizeButton.
  ///
  /// In en, this message translates to:
  /// **'Anonymize'**
  String get anonymizeButton;

  /// No description provided for @sendToLabel.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get sendToLabel;

  /// No description provided for @otherApps.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherApps;

  /// No description provided for @otherAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Other AI apps'**
  String get otherAppsTitle;

  /// Name (without .txt) of the file handed to AI apps and the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Anonymized text'**
  String get sharedFileName;

  /// Name (without .pdf/.docx) of the redacted copy of a PDF or Word file handed to AI apps and the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Anonymized document'**
  String get sharedDocumentName;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear data on this device'**
  String get clearData;

  /// No description provided for @clearDataHint.
  ///
  /// In en, this message translates to:
  /// **'Your latest {count} documents are kept on this device. This deletes them.'**
  String clearDataHint(int count);

  /// No description provided for @clearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every document processed on this device? This cannot be undone.'**
  String get clearDataConfirm;

  /// No description provided for @clearDataAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearDataAction;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'Data on this device cleared.'**
  String get dataCleared;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @dictionaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Always hide'**
  String get dictionaryTitle;

  /// No description provided for @dictionaryHint.
  ///
  /// In en, this message translates to:
  /// **'Type what should be hidden in every document, such as your own name, company or address. The list stays on this phone, and you can still show an item again in one document.'**
  String get dictionaryHint;

  /// No description provided for @dictionaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Text you hide by hand will be suggested here.'**
  String get dictionaryEmpty;

  /// No description provided for @dictionaryWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No words yet} =1{1 word} other{{count} words}}'**
  String dictionaryWords(int count);

  /// No description provided for @dictionarySuggestions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 suggestion} other{{count} suggestions}}'**
  String dictionarySuggestions(int count);

  /// No description provided for @dictionarySuggested.
  ///
  /// In en, this message translates to:
  /// **'Hidden by hand lately'**
  String get dictionarySuggested;

  /// No description provided for @dictionarySeeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dictionarySeeAll;

  /// No description provided for @dictionaryAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden by hand'**
  String get dictionaryAllTitle;

  /// No description provided for @dictionaryAllHint.
  ///
  /// In en, this message translates to:
  /// **'The latest text you hid by hand, up to {count}. Tap one to always hide it.'**
  String dictionaryAllHint(int count);

  /// No description provided for @dictionaryAllEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to suggest yet.'**
  String get dictionaryAllEmpty;

  /// No description provided for @dictionaryAdd.
  ///
  /// In en, this message translates to:
  /// **'Always hide {term}'**
  String dictionaryAdd(String term);

  /// No description provided for @dictionaryRemove.
  ///
  /// In en, this message translates to:
  /// **'Stop hiding {term}'**
  String dictionaryRemove(String term);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @dictionaryInputHint.
  ///
  /// In en, this message translates to:
  /// **'Name, company, address…'**
  String get dictionaryInputHint;

  /// No description provided for @dictionaryAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dictionaryAddButton;

  /// No description provided for @listOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide only this list'**
  String get listOnlyTitle;

  /// No description provided for @listOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Turns automatic detection off: nothing else gets hidden.'**
  String get listOnlyHint;

  /// No description provided for @listOnlyNeedsWords.
  ///
  /// In en, this message translates to:
  /// **'Add a word to the list first.'**
  String get listOnlyNeedsWords;

  /// No description provided for @listOnlyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide only this list?'**
  String get listOnlyConfirmTitle;

  /// No description provided for @listOnlyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Docudis will stop looking for personal details by itself and hide only the words on this list.\n\nCase and accents don\'t matter, but other spellings do: “Jean Dupont” on the list does not hide “Mr Dupont” or “DUPONT J.”, and a phone number written with other spacing stays visible.\n\nEverything not on the list stays readable, such as other people\'s names (a doctor, a landlord, a relative), account, reference and case numbers, and dates of birth.\n\nCheck every result before you send it. You can switch this off at any time.'**
  String get listOnlyConfirmBody;

  /// No description provided for @listOnlyConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Hide only my list'**
  String get listOnlyConfirmAction;

  /// No description provided for @listOnlyCaption.
  ///
  /// In en, this message translates to:
  /// **'only these are hidden'**
  String get listOnlyCaption;

  /// No description provided for @resultListOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Only your Always hide list was applied. Nothing else was checked: read the text before you send it.'**
  String get resultListOnlyNote;

  /// No description provided for @neverHideTitle.
  ///
  /// In en, this message translates to:
  /// **'Never hide'**
  String get neverHideTitle;

  /// No description provided for @neverHideHint.
  ///
  /// In en, this message translates to:
  /// **'Public names the app hides although they need no hiding, such as a council, a bank or a brand. From the next document on, text in this list stays readable. A longer name or address that contains it is still hidden.'**
  String get neverHideHint;

  /// No description provided for @neverHideEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Names you show again by hand will be suggested here.'**
  String get neverHideEmpty;

  /// No description provided for @neverHideInputHint.
  ///
  /// In en, this message translates to:
  /// **'A council, a bank, a brand…'**
  String get neverHideInputHint;

  /// No description provided for @neverHideSuggested.
  ///
  /// In en, this message translates to:
  /// **'Shown again by hand lately'**
  String get neverHideSuggested;

  /// No description provided for @neverHideAdd.
  ///
  /// In en, this message translates to:
  /// **'Never hide {term}'**
  String neverHideAdd(String term);

  /// No description provided for @neverHideRemove.
  ///
  /// In en, this message translates to:
  /// **'Hide {term} again'**
  String neverHideRemove(String term);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyHint.
  ///
  /// In en, this message translates to:
  /// **'How your documents are handled'**
  String get privacyPolicyHint;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactUs;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Docudis {version} ({build})'**
  String appVersion(String version, String build);
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
      <String>['en', 'es', 'fr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

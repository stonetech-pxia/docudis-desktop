// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Docudis';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signUpButton => 'Sign up';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordHint =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get sendResetEmailButton => 'Send reset email';

  @override
  String get resetEmailSent => 'Password reset email sent. Check your inbox.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Sign in with Apple';

  @override
  String get orDivider => 'or';

  @override
  String get noAccountYet => 'No account yet?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signOut => 'Sign out';

  @override
  String get validationEmailRequired => 'Enter your email address.';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Enter a password.';

  @override
  String validationPasswordTooShort(int min) {
    return 'Password must be at least $min characters.';
  }

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get authErrorInvalidEmail => 'The email address is not valid.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect email or password.';

  @override
  String get authErrorEmailInUse =>
      'An account already exists with this email.';

  @override
  String get authErrorWeakPassword => 'The password is too weak.';

  @override
  String get authErrorOperationNotAllowed =>
      'This sign-in method is not enabled.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorNetwork =>
      'Network error. Check your connection and try again.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'An account already exists with this email using a different sign-in method.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String homeSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get anonymizeTitle => 'Protect';

  @override
  String get inputPasteText => 'Paste text';

  @override
  String get inputPickFile => 'Upload a document';

  @override
  String get inputTakePhoto => 'Scan a photo';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get photoFromLibrary => 'Choose from library';

  @override
  String get processing => 'Reading and anonymizing…';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'Nothing processed yet.';

  @override
  String get resultTitle => 'Protected copy';

  @override
  String get tabAnonymized => 'Anonymized';

  @override
  String get tabOriginal => 'Original';

  @override
  String get shareFile => 'Share file';

  @override
  String get sharedImageName => 'Anonymized image';

  @override
  String get shareText => 'Share text';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied.';

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sensitive items',
      one: '1 sensitive item',
      zero: 'No sensitive items',
    );
    return '$_temp0';
  }

  @override
  String get noDetections => 'No sensitive information was found.';

  @override
  String get delete => 'Delete';

  @override
  String get deleteRecordConfirm => 'Delete this record and its restore key?';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllConfirm =>
      'Delete the whole history? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get restoreTitle => 'Restore';

  @override
  String get restoreHint =>
      'Paste the AI\'s reply. Labels are swapped back using the key stored on this phone.';

  @override
  String get entityPerson => 'Name';

  @override
  String get entityEmail => 'Email';

  @override
  String get entityPhone => 'Phone';

  @override
  String get entityId => 'ID number';

  @override
  String get entityCard => 'Card number';

  @override
  String get entityIban => 'IBAN';

  @override
  String get entityDate => 'Date';

  @override
  String get entityAmount => 'Amount';

  @override
  String get entityIp => 'IP address';

  @override
  String get entityUrl => 'URL';

  @override
  String get entityAddress => 'Address / place';

  @override
  String get entityCompany => 'Organization';

  @override
  String get entitySecret => 'Secret / API key';

  @override
  String get entityCustom => 'Custom keyword';

  @override
  String get entityOther => 'Other';

  @override
  String get errorNoText => 'No text could be read from this input.';

  @override
  String get errorUnsupportedFile => 'This file type is not supported yet.';

  @override
  String get errorProcessingFailed => 'Processing failed. Please try again.';

  @override
  String get navAccount => 'Account';

  @override
  String get reviewTitle => 'Change what is hidden';

  @override
  String get reviewHint =>
      'Tap a label to bring the real text back. Tap a name, a number or any other text to hide it. Saved as you go.';

  @override
  String get reviewHideAmounts => 'Hide all amounts';

  @override
  String get reviewHideDates => 'Hide all dates';

  @override
  String get reviewNote =>
      'Replaced with labels like [PERSON_1] so AI answers still make sense.';

  @override
  String get done => 'Done';

  @override
  String resultBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items replaced.',
      one: '1 item replaced.',
      zero: 'Nothing needed replacing.',
    );
    return '$_temp0';
  }

  @override
  String get restoreKeyTitle => 'Restore key kept on this phone';

  @override
  String restoreKeySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pairs · never uploaded · delete anytime',
      one: '1 pair · never uploaded · delete anytime',
    );
    return '$_temp0';
  }

  @override
  String get copyText => 'Copy text';

  @override
  String sendTo(String app) {
    return 'Send to $app';
  }

  @override
  String get aiReplyLabel => 'AI reply';

  @override
  String get paste => 'Paste';

  @override
  String get restoredLabel => 'Restored';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels restored.',
      one: '1 label restored.',
      zero: 'No labels found to restore.',
    );
    return '$_temp0';
  }

  @override
  String get restoreDocumentLabel => 'Document';

  @override
  String get restoreMismatchTitle => 'This reply doesn\'t fit this document';

  @override
  String restoreMismatchBody(String labels) {
    return 'It has labels this document never used: $labels. It is probably the reply to another document: open that one from History and restore it there.';
  }

  @override
  String get restoreShowAnyway => 'Show anyway';

  @override
  String get restoreOtherTitle => 'This reply seems to be for another document';

  @override
  String restoreOtherBody(String name) {
    return 'Its labels and wording fit “$name” better. Restored here, it would get this document\'s names and numbers.';
  }

  @override
  String get restoreUseOther => 'Restore with that document';

  @override
  String restoreInvented(String labels) {
    return 'Not in this document, left as is: $labels';
  }

  @override
  String restoreShownAnyway(String name) {
    return 'Restored with this document\'s key, although the reply fits “$name” better.';
  }

  @override
  String get copyRestored => 'Copy restored text';

  @override
  String get clipboardEmpty => 'The clipboard has no text.';

  @override
  String get confirm => 'Confirm';

  @override
  String get homeHeadline => 'Protect your personal data by anonymizing it.';

  @override
  String get homeCaption => 'Runs entirely on this phone. Nothing is uploaded.';

  @override
  String get anonymizeButton => 'Anonymize';

  @override
  String get sendToLabel => 'Send to';

  @override
  String get otherApps => 'Other';

  @override
  String get otherAppsTitle => 'Other AI apps';

  @override
  String get sharedFileName => 'Anonymized text';

  @override
  String get sharedDocumentName => 'Anonymized document';

  @override
  String get clearData => 'Clear data on this device';

  @override
  String clearDataHint(int count) {
    return 'Your latest $count documents are kept on this device. This deletes them.';
  }

  @override
  String get clearDataConfirm =>
      'Delete every document processed on this device? This cannot be undone.';

  @override
  String get clearDataAction => 'Clear';

  @override
  String get dataCleared => 'Data on this device cleared.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get dictionaryTitle => 'Always hide';

  @override
  String get dictionaryHint =>
      'Type what should be hidden in every document, such as your own name, company or address. The list stays on this phone, and you can still show an item again in one document.';

  @override
  String get dictionaryEmpty =>
      'Nothing yet. Text you hide by hand will be suggested here.';

  @override
  String dictionaryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
      zero: 'No words yet',
    );
    return '$_temp0';
  }

  @override
  String dictionarySuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions',
      one: '1 suggestion',
    );
    return '$_temp0';
  }

  @override
  String get dictionarySuggested => 'Hidden by hand lately';

  @override
  String get dictionarySeeAll => 'All';

  @override
  String get dictionaryAllTitle => 'Hidden by hand';

  @override
  String dictionaryAllHint(int count) {
    return 'The latest text you hid by hand, up to $count. Tap one to always hide it.';
  }

  @override
  String get dictionaryAllEmpty => 'Nothing to suggest yet.';

  @override
  String dictionaryAdd(String term) {
    return 'Always hide $term';
  }

  @override
  String dictionaryRemove(String term) {
    return 'Stop hiding $term';
  }

  @override
  String get rename => 'Rename';

  @override
  String get save => 'Save';

  @override
  String get moreActions => 'More';

  @override
  String get dictionaryInputHint => 'Name, company, address…';

  @override
  String get dictionaryAddButton => 'Add';

  @override
  String get listOnlyTitle => 'Hide only this list';

  @override
  String get listOnlyHint =>
      'Turns automatic detection off: nothing else gets hidden.';

  @override
  String get listOnlyNeedsWords => 'Add a word to the list first.';

  @override
  String get listOnlyConfirmTitle => 'Hide only this list?';

  @override
  String get listOnlyConfirmBody =>
      'Docudis will stop looking for personal details by itself and hide only the words on this list.\n\nCase and accents don\'t matter, but other spellings do: “Jean Dupont” on the list does not hide “Mr Dupont” or “DUPONT J.”, and a phone number written with other spacing stays visible.\n\nEverything not on the list stays readable, such as other people\'s names (a doctor, a landlord, a relative), account, reference and case numbers, and dates of birth.\n\nCheck every result before you send it. You can switch this off at any time.';

  @override
  String get listOnlyConfirmAction => 'Hide only my list';

  @override
  String get listOnlyCaption => 'only these are hidden';

  @override
  String get resultListOnlyNote =>
      'Only your Always hide list was applied. Nothing else was checked: read the text before you send it.';

  @override
  String get neverHideTitle => 'Never hide';

  @override
  String get neverHideHint =>
      'Public names the app hides although they need no hiding, such as a council, a bank or a brand. From the next document on, text in this list stays readable. A longer name or address that contains it is still hidden.';

  @override
  String get neverHideEmpty =>
      'Nothing yet. Names you show again by hand will be suggested here.';

  @override
  String get neverHideInputHint => 'A council, a bank, a brand…';

  @override
  String get neverHideSuggested => 'Shown again by hand lately';

  @override
  String neverHideAdd(String term) {
    return 'Never hide $term';
  }

  @override
  String neverHideRemove(String term) {
    return 'Hide $term again';
  }

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyHint => 'How your documents are handled';

  @override
  String get contactUs => 'Contact';

  @override
  String appVersion(String version, String build) {
    return 'Docudis $version ($build)';
  }
}

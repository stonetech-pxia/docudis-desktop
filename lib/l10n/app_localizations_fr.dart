// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Docudis';

  @override
  String get signInTitle => 'Connexion';

  @override
  String get signUpTitle => 'Créer un compte';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get signUpButton => 'S\'inscrire';

  @override
  String get forgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordHint =>
      'Saisissez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get sendResetEmailButton => 'Envoyer l\'e-mail de réinitialisation';

  @override
  String get resetEmailSent =>
      'E-mail de réinitialisation envoyé. Vérifiez votre boîte de réception.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Se connecter avec Apple';

  @override
  String get orDivider => 'ou';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get validationEmailRequired => 'Saisissez votre adresse e-mail.';

  @override
  String get validationEmailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get validationPasswordRequired => 'Saisissez un mot de passe.';

  @override
  String validationPasswordTooShort(int min) {
    return 'Le mot de passe doit contenir au moins $min caractères.';
  }

  @override
  String get validationPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get authErrorInvalidEmail => 'L\'adresse e-mail n\'est pas valide.';

  @override
  String get authErrorUserDisabled => 'Ce compte a été désactivé.';

  @override
  String get authErrorUserNotFound => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get authErrorWrongPassword => 'E-mail ou mot de passe incorrect.';

  @override
  String get authErrorEmailInUse => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get authErrorWeakPassword => 'Le mot de passe est trop faible.';

  @override
  String get authErrorOperationNotAllowed =>
      'Cette méthode de connexion n\'est pas activée.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get authErrorNetwork =>
      'Erreur réseau. Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'Un compte existe déjà avec cet e-mail via une autre méthode de connexion.';

  @override
  String get authErrorGeneric =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String homeSignedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get anonymizeTitle => 'Protéger';

  @override
  String get inputPasteText => 'Coller du texte';

  @override
  String get inputPickFile => 'Importer un document';

  @override
  String get inputTakePhoto => 'Scanner une photo';

  @override
  String get photoFromCamera => 'Prendre une photo';

  @override
  String get photoFromLibrary => 'Choisir dans la galerie';

  @override
  String get processing => 'Lecture et anonymisation…';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Rien n\'a encore été traité.';

  @override
  String get resultTitle => 'Copie protégée';

  @override
  String get tabAnonymized => 'Anonymisé';

  @override
  String get tabOriginal => 'Original';

  @override
  String get shareFile => 'Partager le fichier';

  @override
  String get sharedImageName => 'Image anonymisée';

  @override
  String get shareText => 'Partager le texte';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié.';

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments sensibles',
      one: '1 élément sensible',
      zero: 'Aucun élément sensible',
    );
    return '$_temp0';
  }

  @override
  String get noDetections => 'Aucune information sensible trouvée.';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteRecordConfirm =>
      'Supprimer cet enregistrement et sa clé de restauration ?';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllConfirm =>
      'Supprimer tout l\'historique ? Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get restoreTitle => 'Restaurer';

  @override
  String get restoreHint =>
      'Collez la réponse de l\'IA. Les étiquettes sont remplacées par les vraies valeurs grâce à la clé conservée sur ce téléphone.';

  @override
  String get entityPerson => 'Nom';

  @override
  String get entityEmail => 'E-mail';

  @override
  String get entityPhone => 'Téléphone';

  @override
  String get entityId => 'Numéro d\'identité';

  @override
  String get entityCard => 'Numéro de carte';

  @override
  String get entityIban => 'IBAN';

  @override
  String get entityDate => 'Date';

  @override
  String get entityAmount => 'Montant';

  @override
  String get entityIp => 'Adresse IP';

  @override
  String get entityUrl => 'URL';

  @override
  String get entityAddress => 'Adresse / lieu';

  @override
  String get entityCompany => 'Organisation';

  @override
  String get entitySecret => 'Secret / clé API';

  @override
  String get entityCustom => 'Mot-clé personnalisé';

  @override
  String get entityOther => 'Autre';

  @override
  String get errorNoText => 'Aucun texte n\'a pu être lu.';

  @override
  String get errorUnsupportedFile =>
      'Ce type de fichier n\'est pas encore pris en charge.';

  @override
  String get errorProcessingFailed =>
      'Le traitement a échoué. Veuillez réessayer.';

  @override
  String get navAccount => 'Compte';

  @override
  String get reviewTitle => 'Modifier ce qui est masqué';

  @override
  String get reviewHint =>
      'Touchez une étiquette pour revoir le texte d\'origine. Touchez un nom, un numéro ou tout autre texte pour le masquer. Enregistré au fur et à mesure.';

  @override
  String get reviewHideAmounts => 'Masquer tous les montants';

  @override
  String get reviewHideDates => 'Masquer toutes les dates';

  @override
  String get reviewNote =>
      'Remplacés par des étiquettes comme [PERSON_1] pour que les réponses de l\'IA restent cohérentes.';

  @override
  String get done => 'Terminé';

  @override
  String resultBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments remplacés.',
      one: '1 élément remplacé.',
      zero: 'Rien à remplacer.',
    );
    return '$_temp0';
  }

  @override
  String get restoreKeyTitle =>
      'Clé de restauration conservée sur ce téléphone';

  @override
  String restoreKeySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paires · jamais envoyées · supprimables à tout moment',
      one: '1 paire · jamais envoyée · supprimable à tout moment',
    );
    return '$_temp0';
  }

  @override
  String get copyText => 'Copier le texte';

  @override
  String sendTo(String app) {
    return 'Envoyer à $app';
  }

  @override
  String get aiReplyLabel => 'Réponse de l\'IA';

  @override
  String get paste => 'Coller';

  @override
  String get restoredLabel => 'Restauré';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étiquettes restaurées.',
      one: '1 étiquette restaurée.',
      zero: 'Aucune étiquette à restaurer.',
    );
    return '$_temp0';
  }

  @override
  String get restoreDocumentLabel => 'Document';

  @override
  String get restoreMismatchTitle =>
      'Cette réponse ne correspond pas à ce document';

  @override
  String restoreMismatchBody(String labels) {
    return 'Elle contient des étiquettes que ce document n\'a jamais utilisées : $labels. C\'est sans doute la réponse à un autre document : ouvrez-le depuis l\'Historique et restaurez-la là.';
  }

  @override
  String get restoreShowAnyway => 'Afficher quand même';

  @override
  String get restoreOtherTitle =>
      'Cette réponse semble destinée à un autre document';

  @override
  String restoreOtherBody(String name) {
    return 'Ses étiquettes et ses mots correspondent mieux à « $name ». Restaurée ici, elle recevrait les noms et numéros de ce document.';
  }

  @override
  String get restoreUseOther => 'Restaurer avec ce document';

  @override
  String restoreInvented(String labels) {
    return 'Absent de ce document, laissé tel quel : $labels';
  }

  @override
  String restoreShownAnyway(String name) {
    return 'Restaurée avec la clé de ce document, bien que la réponse corresponde mieux à « $name ».';
  }

  @override
  String get copyRestored => 'Copier le texte restauré';

  @override
  String get clipboardEmpty => 'Le presse-papiers ne contient pas de texte.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get homeHeadline =>
      'Protégez vos données personnelles en les anonymisant.';

  @override
  String get homeCaption =>
      'Tout se passe sur ce téléphone. Rien n\'est envoyé.';

  @override
  String get anonymizeButton => 'Anonymiser';

  @override
  String get sendToLabel => 'Envoyer à';

  @override
  String get otherApps => 'Autres';

  @override
  String get otherAppsTitle => 'Autres applications IA';

  @override
  String get sharedFileName => 'Texte anonymisé';

  @override
  String get sharedDocumentName => 'Document anonymisé';

  @override
  String get clearData => 'Effacer les données de l\'appareil';

  @override
  String clearDataHint(int count) {
    return 'Vos $count derniers documents sont conservés sur cet appareil. Ceci les supprime.';
  }

  @override
  String get clearDataConfirm =>
      'Supprimer tous les documents traités sur cet appareil ? Cette action est irréversible.';

  @override
  String get clearDataAction => 'Effacer';

  @override
  String get dataCleared => 'Données de l\'appareil effacées.';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get dictionaryTitle => 'Toujours masquer';

  @override
  String get dictionaryHint =>
      'Saisissez ce qui doit être masqué dans chaque document, comme votre nom, votre société ou votre adresse. La liste reste sur ce téléphone, et vous pouvez toujours réafficher un élément dans un document.';

  @override
  String get dictionaryEmpty =>
      'Rien pour l\'instant. Le texte que vous masquez à la main sera proposé ici.';

  @override
  String dictionaryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '1 mot',
      zero: 'Aucun mot pour l\'instant',
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
  String get dictionarySuggested => 'Masqué à la main récemment';

  @override
  String get dictionarySeeAll => 'Tout';

  @override
  String get dictionaryAllTitle => 'Masqué à la main';

  @override
  String dictionaryAllHint(int count) {
    return 'Les derniers textes masqués à la main, $count au maximum. Touchez-en un pour toujours le masquer.';
  }

  @override
  String get dictionaryAllEmpty => 'Rien à proposer pour l\'instant.';

  @override
  String dictionaryAdd(String term) {
    return 'Toujours masquer $term';
  }

  @override
  String dictionaryRemove(String term) {
    return 'Ne plus masquer $term';
  }

  @override
  String get rename => 'Renommer';

  @override
  String get save => 'Enregistrer';

  @override
  String get moreActions => 'Plus';

  @override
  String get dictionaryInputHint => 'Nom, société, adresse…';

  @override
  String get dictionaryAddButton => 'Ajouter';

  @override
  String get listOnlyTitle => 'Masquer uniquement cette liste';

  @override
  String get listOnlyHint =>
      'Désactive la détection automatique : rien d\'autre n\'est masqué.';

  @override
  String get listOnlyNeedsWords => 'Ajoutez d\'abord un mot à la liste.';

  @override
  String get listOnlyConfirmTitle => 'Masquer uniquement cette liste ?';

  @override
  String get listOnlyConfirmBody =>
      'Docudis ne cherchera plus lui-même les données personnelles et masquera seulement les mots de cette liste.\n\nLes majuscules et les accents ne comptent pas, mais une autre écriture, si : « Jean Dupont » dans la liste ne masque ni « M. Dupont » ni « DUPONT J. », et un numéro de téléphone espacé autrement reste visible.\n\nTout ce qui n\'est pas dans la liste reste lisible, par exemple les noms d\'autres personnes (un médecin, un propriétaire, un proche), les numéros de compte, de dossier ou de référence et les dates de naissance.\n\nRelisez chaque résultat avant de l\'envoyer. Vous pouvez désactiver cette option à tout moment.';

  @override
  String get listOnlyConfirmAction => 'Masquer uniquement ma liste';

  @override
  String get listOnlyCaption => 'seuls ces mots sont masqués';

  @override
  String get resultListOnlyNote =>
      'Seule votre liste « Toujours masquer » a été appliquée. Rien d\'autre n\'a été vérifié : relisez le texte avant de l\'envoyer.';

  @override
  String get neverHideTitle => 'Ne jamais masquer';

  @override
  String get neverHideHint =>
      'Des noms publics que l\'app masque sans raison, comme une mairie, une banque ou une marque. À partir du prochain document, le texte de cette liste reste lisible. Un nom ou une adresse plus long qui le contient reste masqué.';

  @override
  String get neverHideEmpty =>
      'Rien pour l\'instant. Les noms que vous réaffichez à la main seront suggérés ici.';

  @override
  String get neverHideInputHint => 'Une mairie, une banque, une marque…';

  @override
  String get neverHideSuggested => 'Réaffichés à la main récemment';

  @override
  String neverHideAdd(String term) {
    return 'Ne jamais masquer $term';
  }

  @override
  String neverHideRemove(String term) {
    return 'Masquer de nouveau $term';
  }

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyHint => 'Comment vos documents sont traités';

  @override
  String get contactUs => 'Contact';

  @override
  String appVersion(String version, String build) {
    return 'Docudis $version ($build)';
  }
}

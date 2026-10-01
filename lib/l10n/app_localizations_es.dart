// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Docudis';

  @override
  String get signInTitle => 'Iniciar sesión';

  @override
  String get signUpTitle => 'Crear cuenta';

  @override
  String get forgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get signUpButton => 'Registrarse';

  @override
  String get forgotPasswordLink => '¿Has olvidado la contraseña?';

  @override
  String get forgotPasswordHint =>
      'Introduce tu correo electrónico y te enviaremos un enlace para restablecer la contraseña.';

  @override
  String get sendResetEmailButton => 'Enviar correo';

  @override
  String get resetEmailSent => 'Correo enviado. Revisa tu bandeja de entrada.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Iniciar sesión con Apple';

  @override
  String get orDivider => 'o';

  @override
  String get noAccountYet => '¿Aún no tienes cuenta?';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get validationEmailRequired => 'Introduce tu correo electrónico.';

  @override
  String get validationEmailInvalid =>
      'Introduce un correo electrónico válido.';

  @override
  String get validationPasswordRequired => 'Introduce una contraseña.';

  @override
  String validationPasswordTooShort(int min) {
    return 'La contraseña debe tener al menos $min caracteres.';
  }

  @override
  String get validationPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get authErrorInvalidEmail => 'El correo electrónico no es válido.';

  @override
  String get authErrorUserDisabled => 'Esta cuenta está desactivada.';

  @override
  String get authErrorUserNotFound => 'No hay ninguna cuenta con este correo.';

  @override
  String get authErrorWrongPassword => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorEmailInUse => 'Ya existe una cuenta con este correo.';

  @override
  String get authErrorWeakPassword => 'La contraseña es demasiado débil.';

  @override
  String get authErrorOperationNotAllowed =>
      'Este método de inicio de sesión no está activado.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Inténtalo de nuevo más tarde.';

  @override
  String get authErrorNetwork =>
      'Error de red. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'Ya existe una cuenta con este correo con otro método de inicio de sesión.';

  @override
  String get authErrorGeneric => 'Algo ha fallado. Inténtalo de nuevo.';

  @override
  String homeSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get anonymizeTitle => 'Proteger';

  @override
  String get inputPasteText => 'Pegar texto';

  @override
  String get inputPickFile => 'Subir un documento';

  @override
  String get inputTakePhoto => 'Escanear una foto';

  @override
  String get photoFromCamera => 'Hacer una foto';

  @override
  String get photoFromLibrary => 'Elegir de la galería';

  @override
  String get processing => 'Leyendo y anonimizando…';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyEmpty => 'Todavía no has procesado nada.';

  @override
  String get resultTitle => 'Copia protegida';

  @override
  String get tabAnonymized => 'Anonimizado';

  @override
  String get tabOriginal => 'Original';

  @override
  String get shareFile => 'Compartir archivo';

  @override
  String get sharedImageName => 'Imagen anonimizada';

  @override
  String get shareText => 'Compartir texto';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado.';

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datos sensibles',
      one: '1 dato sensible',
      zero: 'Ningún dato sensible',
    );
    return '$_temp0';
  }

  @override
  String get noDetections => 'No se ha encontrado información sensible.';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteRecordConfirm =>
      '¿Eliminar este registro y su clave de restauración?';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get deleteAllConfirm =>
      '¿Eliminar todo el historial? No se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get restoreTitle => 'Restaurar';

  @override
  String get restoreHint =>
      'Pega la respuesta de la IA. Las etiquetas se sustituyen por los datos reales con la clave guardada en este teléfono.';

  @override
  String get entityPerson => 'Nombre';

  @override
  String get entityEmail => 'Correo electrónico';

  @override
  String get entityPhone => 'Teléfono';

  @override
  String get entityId => 'Número de identificación';

  @override
  String get entityCard => 'Número de tarjeta';

  @override
  String get entityIban => 'IBAN';

  @override
  String get entityDate => 'Fecha';

  @override
  String get entityAmount => 'Importe';

  @override
  String get entityIp => 'Dirección IP';

  @override
  String get entityUrl => 'URL';

  @override
  String get entityAddress => 'Dirección / lugar';

  @override
  String get entityCompany => 'Organización';

  @override
  String get entitySecret => 'Secreto / clave de API';

  @override
  String get entityCustom => 'Palabra personalizada';

  @override
  String get entityOther => 'Otro';

  @override
  String get errorNoText => 'No se ha podido leer ningún texto.';

  @override
  String get errorUnsupportedFile =>
      'Este tipo de archivo aún no es compatible.';

  @override
  String get errorProcessingFailed =>
      'No se ha podido procesar. Inténtalo de nuevo.';

  @override
  String get navAccount => 'Cuenta';

  @override
  String get reviewTitle => 'Cambiar lo que se oculta';

  @override
  String get reviewHint =>
      'Toca una etiqueta para recuperar el texto real. Toca un nombre, un número o cualquier otro texto para ocultarlo. Se guarda al momento.';

  @override
  String get reviewHideAmounts => 'Ocultar todos los importes';

  @override
  String get reviewHideDates => 'Ocultar todas las fechas';

  @override
  String get reviewNote =>
      'Se sustituye por etiquetas como [PERSON_1] para que las respuestas de la IA sigan teniendo sentido.';

  @override
  String get done => 'Hecho';

  @override
  String resultBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datos sustituidos.',
      one: '1 dato sustituido.',
      zero: 'No había nada que sustituir.',
    );
    return '$_temp0';
  }

  @override
  String get restoreKeyTitle =>
      'Clave de restauración guardada en este teléfono';

  @override
  String restoreKeySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pares · nunca se suben · bórralos cuando quieras',
      one: '1 par · nunca se sube · bórrala cuando quieras',
    );
    return '$_temp0';
  }

  @override
  String get copyText => 'Copiar texto';

  @override
  String sendTo(String app) {
    return 'Enviar a $app';
  }

  @override
  String get aiReplyLabel => 'Respuesta de la IA';

  @override
  String get paste => 'Pegar';

  @override
  String get restoredLabel => 'Restaurado';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etiquetas restauradas.',
      one: '1 etiqueta restaurada.',
      zero: 'No hay etiquetas que restaurar.',
    );
    return '$_temp0';
  }

  @override
  String get restoreDocumentLabel => 'Documento';

  @override
  String get restoreMismatchTitle =>
      'Esta respuesta no corresponde a este documento';

  @override
  String restoreMismatchBody(String labels) {
    return 'Contiene etiquetas que este documento nunca ha usado: $labels. Seguramente es la respuesta a otro documento: ábrelo desde el Historial y restáurala allí.';
  }

  @override
  String get restoreShowAnyway => 'Mostrar de todos modos';

  @override
  String get restoreOtherTitle => 'Esta respuesta parece ser de otro documento';

  @override
  String restoreOtherBody(String name) {
    return 'Sus etiquetas y su texto encajan mejor con «$name». Si la restauras aquí, recibirá los nombres y números de este documento.';
  }

  @override
  String get restoreUseOther => 'Restaurar con ese documento';

  @override
  String restoreInvented(String labels) {
    return 'No está en este documento, se deja tal cual: $labels';
  }

  @override
  String restoreShownAnyway(String name) {
    return 'Restaurada con la clave de este documento, aunque la respuesta encaja mejor con «$name».';
  }

  @override
  String get copyRestored => 'Copiar texto restaurado';

  @override
  String get clipboardEmpty => 'El portapapeles no tiene texto.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get homeHeadline => 'Protege tus datos personales anonimizándolos.';

  @override
  String get homeCaption => 'Todo se hace en este teléfono. No se sube nada.';

  @override
  String get anonymizeButton => 'Anonimizar';

  @override
  String get sendToLabel => 'Enviar a';

  @override
  String get otherApps => 'Otras';

  @override
  String get otherAppsTitle => 'Otras apps de IA';

  @override
  String get sharedFileName => 'Texto anonimizado';

  @override
  String get sharedDocumentName => 'Documento anonimizado';

  @override
  String get clearData => 'Borrar los datos de este dispositivo';

  @override
  String clearDataHint(int count) {
    return 'Tus últimos $count documentos se guardan en este dispositivo. Esto los borra.';
  }

  @override
  String get clearDataConfirm =>
      '¿Borrar todos los documentos procesados en este dispositivo? No se puede deshacer.';

  @override
  String get clearDataAction => 'Borrar';

  @override
  String get dataCleared => 'Datos de este dispositivo borrados.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get dictionaryTitle => 'Ocultar siempre';

  @override
  String get dictionaryHint =>
      'Escribe lo que debe ocultarse en todos los documentos, como tu nombre, tu empresa o tu dirección. La lista se queda en este teléfono y puedes volver a mostrar un elemento en un documento concreto.';

  @override
  String get dictionaryEmpty =>
      'Nada todavía. Aquí se sugerirá el texto que ocultes a mano.';

  @override
  String dictionaryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras',
      one: '1 palabra',
      zero: 'Ninguna palabra',
    );
    return '$_temp0';
  }

  @override
  String dictionarySuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sugerencias',
      one: '1 sugerencia',
    );
    return '$_temp0';
  }

  @override
  String get dictionarySuggested => 'Ocultado a mano hace poco';

  @override
  String get dictionarySeeAll => 'Todo';

  @override
  String get dictionaryAllTitle => 'Ocultado a mano';

  @override
  String dictionaryAllHint(int count) {
    return 'Lo último que has ocultado a mano, hasta $count. Toca uno para ocultarlo siempre.';
  }

  @override
  String get dictionaryAllEmpty => 'Nada que sugerir todavía.';

  @override
  String dictionaryAdd(String term) {
    return 'Ocultar siempre $term';
  }

  @override
  String dictionaryRemove(String term) {
    return 'Dejar de ocultar $term';
  }

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get save => 'Guardar';

  @override
  String get moreActions => 'Más';

  @override
  String get dictionaryInputHint => 'Nombre, empresa, dirección…';

  @override
  String get dictionaryAddButton => 'Añadir';

  @override
  String get listOnlyTitle => 'Ocultar solo esta lista';

  @override
  String get listOnlyHint =>
      'Desactiva la detección automática: no se oculta nada más.';

  @override
  String get listOnlyNeedsWords => 'Primero añade una palabra a la lista.';

  @override
  String get listOnlyConfirmTitle => '¿Ocultar solo esta lista?';

  @override
  String get listOnlyConfirmBody =>
      'Docudis dejará de buscar datos personales por su cuenta y solo ocultará las palabras de esta lista.\n\nLas mayúsculas y los acentos no importan, pero otra forma de escribirlas sí: «Jean Dupont» en la lista no oculta «Sr. Dupont» ni «DUPONT J.», y un teléfono escrito con otros espacios queda visible.\n\nTodo lo que no esté en la lista queda legible, por ejemplo los nombres de otras personas (un médico, un casero, un familiar), los números de cuenta, de expediente o de referencia y las fechas de nacimiento.\n\nRevisa cada resultado antes de enviarlo. Puedes desactivarlo cuando quieras.';

  @override
  String get listOnlyConfirmAction => 'Ocultar solo mi lista';

  @override
  String get listOnlyCaption => 'solo se ocultan estas';

  @override
  String get resultListOnlyNote =>
      'Solo se ha aplicado tu lista «Ocultar siempre». No se ha comprobado nada más: revisa el texto antes de enviarlo.';

  @override
  String get neverHideTitle => 'No ocultar nunca';

  @override
  String get neverHideHint =>
      'Nombres públicos que la app oculta sin necesidad, como un ayuntamiento, un banco o una marca. A partir del próximo documento, el texto de esta lista queda legible. Un nombre o una dirección más largos que lo contengan se siguen ocultando.';

  @override
  String get neverHideEmpty =>
      'Nada todavía. Aquí se sugerirán los nombres que vuelvas a mostrar a mano.';

  @override
  String get neverHideInputHint => 'Un ayuntamiento, un banco, una marca…';

  @override
  String get neverHideSuggested => 'Vueltos a mostrar a mano hace poco';

  @override
  String neverHideAdd(String term) {
    return 'No ocultar nunca $term';
  }

  @override
  String neverHideRemove(String term) {
    return 'Volver a ocultar $term';
  }

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicyHint => 'Cómo se tratan tus documentos';

  @override
  String get contactUs => 'Contacto';

  @override
  String appVersion(String version, String build) {
    return 'Docudis $version ($build)';
  }
}

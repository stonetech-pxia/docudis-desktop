/// Kinds of sensitive information the engine can detect.
///
/// Local copy of docudis-android's `docudis_engine` EntityType, which mirrors
/// docudis-core's `EntityType`. Replace with the typed models once they land
/// in docudis-core's Dart bindings (`docudis_ffi`).
///
/// [placeholderName] is the stable, English, uppercase label used inside
/// placeholders such as `[PERSON_1]`; it never changes with the UI locale.
enum EntityType {
  person('PERSON'),
  email('EMAIL'),
  phone('PHONE'),

  /// Government identifiers: national ID cards, passports, SSN-like numbers.
  id('ID'),

  /// A digit string a loose rule matched: some identifier, but claiming a
  /// specific kind would be a guess that misleads whoever reads the output.
  number('NUMBER'),
  card('CARD'),
  iban('IBAN'),

  /// Detected but left visible by default, like [amount].
  date('DATE'),

  /// A [date] that follows a "born" / "date of birth" label.
  birthDate('BIRTH_DATE'),
  amount('AMOUNT'),
  ip('IP'),
  url('URL'),
  address('ADDRESS'),
  company('COMPANY'),
  secret('SECRET'),
  apiKey('API_KEY'),

  /// User-supplied dictionary terms.
  custom('CUSTOM'),
  other('OTHER');

  const EntityType(this.placeholderName);

  final String placeholderName;

  /// Resolves a placeholder label or a DocCloak rule-pack `entityType` name.
  static EntityType? fromName(String name) {
    switch (name) {
      case 'SSN':
        return EntityType.id;
      case 'CREDIT_CARD':
        return EntityType.card;
      case 'CURRENCY':
        return EntityType.amount;
      case 'IP_ADDRESS':
        return EntityType.ip;
    }
    for (final t in EntityType.values) {
      if (t.placeholderName == name) return t;
    }
    return null;
  }
}

import 'package:docudis_ffi/docudis_ffi.dart';

import '../../l10n/app_localizations.dart';

/// What a detection is, in the interface language.
String entityLabel(AppLocalizations l10n, EntityType type) => switch (type) {
  EntityType.person => l10n.entityPerson,
  EntityType.email => l10n.entityEmail,
  EntityType.phone => l10n.entityPhone,
  EntityType.id || EntityType.number => l10n.entityId,
  EntityType.card => l10n.entityCard,
  EntityType.iban => l10n.entityIban,
  EntityType.date || EntityType.birthDate => l10n.entityDate,
  EntityType.amount => l10n.entityAmount,
  EntityType.ip => l10n.entityIp,
  EntityType.url => l10n.entityUrl,
  EntityType.address => l10n.entityAddress,
  EntityType.company => l10n.entityCompany,
  EntityType.secret || EntityType.apiKey => l10n.entitySecret,
  EntityType.custom => l10n.entityCustom,
  EntityType.other => l10n.entityOther,
};

# Docudis en entreprise

Cette page s'adresse aux équipes informatiques, aux DPO et aux services juridiques qui doivent décider si Docudis peut être utilisé sur les postes de travail. Elle porte sur la version Windows (et macOS) de [Docudis Desktop](https://github.com/stonetech-pxia/docudis-desktop).

## Qui publie Docudis

Docudis est un logiciel libre publié par un développeur indépendant, Pengda Xia (stonetech), en France. Il n'y a ni société, ni version payante, ni contrat de support.

- Code source : <https://github.com/stonetech-pxia/docudis-desktop>
- Contact : stonetechdigital@gmail.com
- Signaler une vulnérabilité : [SECURITY.md](../SECURITY.md)
- Politique de confidentialité : <https://docudis.com/privacy/desktop/>

## Ce que fait l'application

Docudis repère les données personnelles (noms, adresses, numéros, etc.) dans un texte, un document Word ou un PDF qui contient du texte, et les remplace par des balises. L'utilisateur relit et corrige le résultat avant de le copier, par exemple dans un assistant d'IA. Une table de correspondance conservée sur le poste permet ensuite de rétablir les vraies valeurs dans la réponse de l'IA.

Les images et les PDF numérisés ne sont pas encore pris en charge. Si une seule page d'un PDF n'a pas de texte, Docudis ne produit pas de PDF masqué, seulement du texte, pour qu'aucune page numérisée ne sorte sans masquage.

## Aucune connexion réseau

- Tout le traitement (détection, masquage, rétablissement, modèle de reconnaissance des noms) se fait sur le poste.
- Pas de compte, pas de statistiques, pas de rapport de plantage, pas de mise à jour automatique.
- La seule action réseau possible : quand l'utilisateur clique sur un lien dans les réglages (politique de confidentialité, contact), le navigateur l'ouvre.
- ONNX Runtime, qui fait tourner le modèle, est compilé depuis les sources de Microsoft sans télémétrie ; la version officielle pour Windows enregistre des événements dans le groupe de télémétrie de Microsoft.

Comment c'est vérifié : des tests automatiques contrôlent que le code de l'application, ses dépendances et les fichiers livrés ne contiennent rien qui se connecte au réseau, et le test d'intégration relève toutes les connexions ouvertes par l'application pendant un parcours complet (résultat : aucune). La méthode et les résultats détaillés sont dans [network-audit.md](network-audit.md) (en chinois pour l'instant).

Sous Windows, aucun bac à sable n'empêche l'application de se connecter. Pour l'imposer au niveau du système, ajoutez une règle de pare-feu (PowerShell administrateur, avec le chemin réel de `docudis.exe`) :

```powershell
New-NetFirewallRule -DisplayName "Docudis - block outbound" -Direction Outbound -Action Block -Program "C:\Tools\Docudis\docudis.exe"
```

Sous macOS, l'application tourne dans le bac à sable d'Apple sans aucun droit d'accès au réseau ; c'est le système qui bloque les connexions.

## Données enregistrées sur le poste

Docudis enregistre ses données dans `%APPDATA%\stonetech\Docudis\` (sous macOS : `~/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/`), ainsi que dans les fichiers que l'utilisateur choisit d'enregistrer.

| Emplacement | Contenu |
|---|---|
| `records\` | Pour chaque document traité : le texte d'origine, le résultat masqué, les détections avec la table de correspondance, et une copie du fichier importé. Les 100 derniers documents sont conservés, les plus anciens sont supprimés automatiquement. |
| `dictionary.json`, `never_hide.json` | Les listes « toujours masquer » et « ne jamais masquer » de l'utilisateur. |
| `models\` | Modèles de reconnaissance des noms installés séparément (facultatif). |
| réglages | Langue de l'interface et options. |

**Ces données sont enregistrées en clair, sans chiffrement propre à l'application.** Elles contiennent les documents d'origine. Docudis n'exclut pas ce dossier des sauvegardes : les profils itinérants (`%APPDATA%` est le dossier Roaming), la redirection de dossiers et les sauvegardes du poste peuvent le copier sur un serveur. Nous recommandons :

- le chiffrement du disque (BitLocker, FileVault) ;
- avec des profils itinérants, d'exclure `AppData\Roaming\stonetech\Docudis` de la synchronisation (stratégie de groupe « Exclure des répertoires du profil itinérant ») ;
- le bouton « Effacer les données de l'appareil » dans les réglages, qui supprime tous les documents traités (les listes et les réglages restent) ;
- pour désinstaller : supprimer le dossier de l'application, puis `%APPDATA%\stonetech\Docudis\`.

## Pour le DPO

- Docudis ne transmet aucune donnée à son éditeur ni à des tiers. L'éditeur n'a accès à aucune donnée et n'est donc pas sous-traitant au sens de l'article 28 du RGPD ; le traitement reste entièrement sous la responsabilité de votre organisation.
- Le texte produit est **pseudonymisé, pas anonymisé** au sens du RGPD (article 4, point 5) : la table de correspondance conservée sur le poste permet de retrouver les valeurs d'origine, et le contexte restant peut parfois suffire à identifier une personne.
- La détection est automatique et peut manquer des éléments ou en masquer à tort. L'utilisateur doit relire le résultat avant de le partager ; l'interface est conçue pour cette relecture.

## Pour le service juridique : la licence

Docudis Desktop est sous [GNU AGPL-3.0](../LICENSE). Les bibliothèques de détection (docudis-core, docudis-ner) sont sous Apache-2.0.

- **Utiliser Docudis dans l'entreprise, sur autant de postes que nécessaire, sans le modifier, n'impose aucune obligation.** Copier le logiciel pour les postes de sa propre organisation n'est pas une distribution au sens de la licence.
- Les obligations de l'AGPL ne s'appliquent que si vous **distribuez** Docudis à d'autres (fournir le code source correspondant, sous la même licence) ou si vous **modifiez** Docudis et le mettez à disposition d'utilisateurs à travers un réseau (leur proposer le code source modifié).
- Le logiciel est fourni sans garantie (articles 15 et 16 de la licence).

## Installation et vérification

- Docudis est livré sous forme de zip : pas d'installation, pas de droits administrateur, aucune modification des réglages du système. Le runtime Visual C++ nécessaire est inclus.
- Chaque version est construite par GitHub Actions à partir d'un tag du dépôt public, et non sur la machine d'un développeur. Elle est publiée avec son empreinte SHA-256 et une attestation de provenance, vérifiable avec :

  ```
  gh attestation verify docudis-<version>-windows-x64.zip -R stonetech-pxia/docudis-desktop
  ```

- La version Windows n'est pas encore signée ; une demande de signature gratuite pour les logiciels libres est en préparation auprès de SignPath Foundation. Voir [Code signing policy](code-signing-policy.md). En attendant, SmartScreen peut afficher un avertissement au premier lancement, et une liste d'autorisation peut s'appuyer sur l'empreinte SHA-256.
- La liste complète des composants tiers et de leurs licences figure dans l'application, sous Réglages > Licences open source.

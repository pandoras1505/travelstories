# Déploiement

## Prérequis

- Flutter 3.41.6 (stable), Dart ^3.11.4.
- Un projet Firebase (`travelstories-app`) avec **Auth** (Email/Password + Google) et **Firestore** activés. **Storage nécessite le plan payant Blaze** — voir plus bas.
- Pour un build Android : JDK 17.
- Pour un build iOS : macOS + Xcode (aucun runner de ce type n'est configuré dans ce projet à ce jour).

## Configuration Firebase

Trois fichiers de configuration sont **commités dans le dépôt**, volontairement :

| Fichier | Plateforme |
|---|---|
| `android/app/google-services.json` | Android |
| `ios/Runner/GoogleService-Info.plist` | iOS |
| `lib/firebase_options.dart` | Toutes (généré par FlutterFire CLI) |

Ce sont des **clés client publiques** (elles identifient l'app auprès de Firebase), pas des secrets serveur — la vraie protection des données vient des Security Rules (voir [SECURITY.md](SECURITY.md)), pas du secret de ces fichiers. C'est pourquoi la CI n'a besoin d'aucun secret injecté pour construire l'app.

`ios/Runner/GoogleService-Info.plist` a été placé manuellement dans ce projet : la FlutterFire CLI ne peut pas le générer depuis Windows sans Xcode.

### Régénérer `google-services.json`

Si l'empreinte SHA-1 de signature change (nouveau keystore, nouvelle machine de build) ou qu'un client OAuth doit être ajouté :

1. [Console Firebase](https://console.firebase.google.com) → **travelstories-app** → icône engrenage → *Paramètres du projet*.
2. Sous "Vos applications", sélectionner l'app Android (`com.travelstories.app`).
3. *Ajouter une empreinte* → coller le SHA-1 (voir plus bas comment l'obtenir).
4. Télécharger le `google-services.json` régénéré et remplacer `android/app/google-services.json`.

## Règles et index Firestore/Storage

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage    # uniquement une fois Storage activé
```

`firestore.indexes.json` définit 4 index composites, nécessaires au tri/recherche d'Explorer (`isPublic+createdAt`, `ownerId+updatedAt`, `isPublic+experienceCount+createdAt`, `isPublic+title+createdAt`).

## Firebase Storage — statut actuel : non activé, contourné par un stockage local

Storage nécessite le plan **Blaze** (facturation à l'usage, carte bancaire requise même pour rester dans le quota gratuit) depuis fin 2024 — indisponible pour ce projet. Plutôt que de bloquer l'upload de médias, `AvatarStorageDataSource`/`CoverStorageDataSource`/`ExperienceMediaStorageDataSource` écrivent directement sur le disque de l'appareil (voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md#médias--stockage-local-en-attendant-storage) pour le détail) — c'est un choix délibéré de l'utilisateur, pas un correctif temporaire oublié.

- `storage.rules` reste écrit et durci (voir [SECURITY.md](SECURITY.md)) mais **ne peut pas être déployé** (`firebase deploy --only storage` échoue tant que le bucket par défaut n'existe pas) et n'est de toute façon plus sollicité par l'app tant que le bypass local est actif.
- La dépendance `firebase_storage` (`pubspec.yaml`) est gardée mais **n'est plus importée nulle part dans `lib/`** — conservée pour ne pas complexifier une réactivation future, pas retirée comme une dépendance inutilisée ordinaire (voir `PRODUCTION_READINESS.md` pour le distinguo avec `firebase_analytics`, qui lui est un oubli, pas un choix).
- **Conséquence produit à connaître** : un média n'est visible que sur l'appareil qui l'a créé — un carnet publié ne montre ses photos/vidéos qu'à son propriétaire, jamais aux autres utilisateurs ni aux autres appareils du même compte, tant que Storage n'est pas activé.

**Pour activer Storage et revenir à un vrai stockage cloud** :
1. Console Firebase → Storage → *Get Started* → passer au plan Blaze.
2. `firebase deploy --only storage`.
3. Réécrire les 3 classes `*StorageDataSource` pour appeler `FirebaseStorage.instance` comme avant (voir l'historique git de ces fichiers pour la version pré-bypass) — aucun autre fichier (repository, écran, schéma Firestore) n'a besoin de changer, `AppImage`/`appImageProvider` gèrent déjà indifféremment une URL `https://` ou un chemin local.

## Empreintes SHA-1 (Google Sign-In Android)

Google Sign-In sur Android exige que l'empreinte SHA-1 du keystore de signature soit enregistrée dans la console Firebase.

### Debug

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

(Sur Windows, remplacer `~/.android/debug.keystore` par `%USERPROFILE%\.android\debug.keystore` ; utiliser le `keytool.exe` fourni avec un JDK.)

Alternative si Gradle fonctionne dans l'environnement : `cd android && ./gradlew signingReport`.

### Release

`android/app/build.gradle.kts` signe actuellement la configuration `release` avec la clé de **debug** (`TODO: Add your own signing config for the release build`, laissé par `flutter create`) — aucun keystore de release n'a encore été créé.

Pour en générer un (à faire une seule fois, **le fichier et son mot de passe doivent être précieusement sauvegardés** — le perdre signifie ne plus jamais pouvoir republier une mise à jour de l'app sous la même identité sur le Play Store) :

```bash
keytool -genkeypair -v -keystore release-keystore.jks -alias travelstories -keyalg RSA -keysize 2048 -validity 10000
```

Puis référencer ce keystore dans `android/app/build.gradle.kts` (`signingConfigs.create("release") { ... }`) et ajouter son SHA-1 dans la console Firebase, comme pour le debug.

## CI/CD

`.github/workflows/ci.yml` — déclenché sur push/PR vers `main` et manuellement (`workflow_dispatch`) :

| Job | Contenu |
|---|---|
| `analyze_and_test` | `pub get` → `build_runner build` (régénère les `*.freezed.dart`, gitignorés) → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test` |
| `build_android` | JDK 17 → `flutter build apk --debug` → upload de l'APK en artefact (rétention 7 jours) |

Points d'attention :
- **`build_runner build` est une étape explicite obligatoire** : contrairement à `flutter gen-l10n` (qui se relance seul via `generate: true` dans `pubspec.yaml`), les fichiers `*.freezed.dart` sont gitignorés — un checkout frais n'en a aucun, et la moitié des entités du domaine sont des classes `@freezed`.
- **Les filtres `on.push.branches`/`on.pull_request.branches` doivent correspondre au nom réel de la branche par défaut du dépôt** (`main`, pas `master`) — un écart ne produit aucune erreur visible, juste un workflow qui n'apparaît jamais dans l'historique des runs.
- Pas de job iOS (runner macOS + signature Apple requis, aucun des deux n'est configuré) ni de publication automatique (Play Store/TestFlight).

`.github/dependabot.yml` ouvre des PR hebdomadaires pour les dépendances `pub` et les actions GitHub utilisées dans `ci.yml`.

## Build Android

```bash
flutter build apk --debug      # ne nécessite pas de keystore de release
flutter build apk --release    # nécessite un keystore de release configuré (voir plus haut)
flutter build appbundle        # pour publication sur le Play Store
```

## Build iOS

Nécessite macOS + Xcode + un compte développeur Apple (`REVERSED_CLIENT_ID` pour Google Sign-In est déjà câblé dans `Info.plist`). Non testé dans le cadre de ce projet faute d'environnement macOS disponible.

```bash
flutter build ios --release
```

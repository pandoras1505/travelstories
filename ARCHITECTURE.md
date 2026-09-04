# Architecture

## Vue d'ensemble

TravelStories suit une **Clean Architecture en feature-first** : chaque fonctionnalité métier (`lib/features/<feature>/`) est un module quasi autonome découpé en trois couches, et le code transverse (thème, erreurs, sync, réseau local) vit dans `lib/core/`.

```
lib/
  app/                      # Point d'entrée applicatif : router, shell à onglets
  core/
    connectivity/           # État réseau (ConnectivityService)
    database/               # Schéma SQLite (AppDatabaseSchema, openAppDatabase)
    errors/                 # Hiérarchie AppException
    localization/           # Fichiers .arb + classes générées (gen-l10n)
    offline/                # localFirstStream / localFirstSingleStream
    sync/                   # SyncEngine + file de mutations
    theme/                  # Design tokens (AppSpacing, AppRadius, AppShadows, AppImageCache)
    utils/                  # Validators, mappers d'erreurs
    widgets/                # Widgets partagés (états de chargement/erreur, bandeau offline)
  features/
    authentication/
    profile/
    travel_books/
    experiences/
    exploration/
    home/
    location/
    media/
```

Chaque feature reproduit systématiquement :

```
features/<feature>/
  domain/
    entities/          # Modèles @freezed, immuables
    repositories/       # Interfaces abstraites (contrat, pas d'implémentation)
  data/
    datasources/        # Un par source physique : *FirestoreDataSource, *LocalDataSource
    repositories/        # Implémentation concrète de l'interface domain
  presentation/
    providers/           # Providers Riverpod (accès en lecture, DI)
    controllers/          # AsyncNotifier pour les actions mutantes (formulaires, etc.)
    screens/
    widgets/
```

Le domaine ne connaît ni Firestore ni SQLite ni Riverpod : une entité `TravelBook` est un simple objet `@freezed`, et `TravelBookRepository` est une interface abstraite. Toute la mécanique (Firestore, cache local, mapping d'exceptions) reste dans la couche `data`.

## Gestion d'état : Riverpod sans codegen

Tous les providers sont **écrits à la main** (`Provider`, `StreamProvider`, `StreamProvider.family`, `AsyncNotifier`/`AsyncNotifierProvider`) — pas de `riverpod_generator`. Raison : le générateur entre en conflit de version (`meta`) avec le SDK Flutter utilisé par ce projet.

Convention suivie partout :
- Un provider **de lecture** (`StreamProvider`, `FutureProvider`) expose l'état courant d'une entité ou d'une liste, via le repository.
- Un **controller** (`AsyncNotifier<T>`) porte les actions qui mutent l'état (créer, éditer, publier...). Une méthode de controller qui déclenche une action ponctuelle (envoyer un email, sauvegarder un profil) **retourne directement `Future<bool>`** (succès ou non) plutôt que de faire déduire le succès à l'écran depuis la transition d'état du provider — un piège réel rencontré en pratique : `previous is AsyncLoading && next is AsyncData` se déclenche aussi bien à l'ouverture de l'écran (résolution du `build()` initial du controller) qu'après une vraie action utilisateur.

## Navigation

`go_router`, exposé par `appRouterProvider` (un `Provider<GoRouter>`, pas un singleton global) — nécessaire pour rester testable : les tests peuvent overrider `authRepositoryProvider` avec un faux repository et le router en tient compte. `redirect` lit `authRepository.currentUser` directement (le router vit hors de l'arbre de widgets) et se réévalue à chaque changement d'état d'authentification via un `GoRouterRefreshStream`.

Structure des routes (voir `lib/app/router/app_router.dart`) :
- `/splash`, `/login`, `/register`, `/forgot-password` — hors du shell à onglets.
- Un `StatefulShellRoute.indexedStack` à 5 branches : **Accueil**, **Explorer**, **Créer un carnet**, **Mes carnets** (avec détail/édition d'un carnet et création/édition d'une expérience en sous-routes), **Profil**.

## Hiérarchie d'erreurs

`lib/core/errors/app_exception.dart` définit une `sealed class AppException` avec un sous-type par domaine technique : `AuthException`, `NetworkException`, `FirestoreException`, `StorageException`, `DatabaseException`, `LocationException`, `MediaException`, `SyncException`. Chaque implémentation de repository mappe les exceptions du SDK natif (`FirebaseException`, etc.) vers ce type au moment où elles traversent la couche `data` — la couche `presentation` ne voit jamais un message ou un code d'erreur brut du SDK. Les écrans traduisent ensuite le `code` optionnel en message localisé via des fonctions de mapping dédiées (une par domaine : `auth_error_messages.dart`, `media_error_messages.dart`, etc.).

## Modèles de domaine et localisation

- **Entités** : classes `@freezed`, générées via `dart run build_runner build` (les fichiers `*.freezed.dart` sont gitignorés — à régénérer après chaque checkout frais ou changement de schéma).
- **i18n texte** (fr/en) : `flutter gen-l10n`, sources dans `lib/core/localization/l10n/app_{fr,en}.arb`, généré automatiquement à chaque `flutter pub get` (`generate: true` dans `pubspec.yaml`).

## Médias

Le pipeline est le même partout (avatar, couverture de carnet, média d'expérience) : compression côté client (`flutter_image_compress`, cap à 2560px de long côté) → stockage du fichier → mise à jour du document Firestore correspondant, jamais l'inverse. Les vidéos ne sont pas recompressées côté client (packages jugés trop fragiles) ; leur durée est plafonnée à 60 secondes à la capture.

**Stockage actuel : local, pas Firebase Storage** (Storage n'est pas activé — voir [DEPLOYMENT.md](DEPLOYMENT.md)). `AvatarStorageDataSource`/`CoverStorageDataSource`/`ExperienceMediaStorageDataSource` (une par feature, comme avant) écrivent désormais sur le disque de l'appareil via `lib/core/media/local_media_store.dart`, en reproduisant exactement l'arborescence de chemins qu'utilisait Firebase Storage (`users/{uid}/profile/...`, `travelBooks/{id}/cover/...`, `travelBooks/{id}/experiences/{id}/...`) sous `<répertoire documents de l'app>/media/`. Le champ Firestore (`photoUrl`/`coverImageUrl`/`mediaUrl`/`thumbnailUrl`) contient donc un chemin de fichier local, pas une URL `https://`. Détail complet dans [OFFLINE_SYNC.md](OFFLINE_SYNC.md#médias--stockage-local-en-attendant-storage).

L'affichage gère les deux cas de figure de façon transparente via `AppImage`/`appImageProvider` (`lib/core/widgets/app_image.dart`) — un chemin `http(s)://` est rendu comme avant via `CachedNetworkImage`, un chemin local via `Image.file`/`FileImage`. Aucun écran n'a besoin de savoir lequel des deux il affiche.

## Carte

Toute dépendance à un fournisseur de carte est confinée à deux fichiers (`location_picker_screen.dart`, `experience_map_preview.dart`), ce qui a permis de passer de Google Maps à **OpenStreetMap** (`flutter_map`) sans toucher au reste de l'app — Google Maps nécessite une carte bancaire pour la facturation, indisponible pour ce projet. `latitude`/`longitude`/`locationName` sont optionnels sur une `Experience` : la saisie manuelle du lieu fonctionne sans jamais toucher au plugin de géolocalisation.

## Hors ligne et synchronisation

Voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md) pour le détail : lecture locale-first via SQLite, écritures optimistes rejouées par un `SyncEngine` générique.

## Sécurité

Voir [SECURITY.md](SECURITY.md) : tout le contrôle d'accès aux données est appliqué par les Firestore/Storage Security Rules, pas par le client.

## Tests

Convention stricte : **jamais de faux/mock du SDK Firebase**. Chaque interface de repository a un *fake* maison en mémoire (`test/fakes/`) — `FakeAuthRepository`, `FakeProfileRepository`, `FakeTravelBookRepository`, `FakeExperienceRepository`, `FakeLocationRepository`, `FakeConnectivityService`. Les tests widgets injectent ces fakes via `ProviderScope(overrides: [...])`. La logique offline pure (`localFirstStream`, `SyncEngine`) est extraite en utilitaires Dart sans dépendance Firebase, ce qui permet de la tester unitairement sans violer cette règle.

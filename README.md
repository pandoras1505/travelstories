# TravelStories

> Transformez vos voyages en histoires.

TravelStories est une application Flutter de carnets de voyage : chaque utilisateur crée des **carnets** (`TravelBook`) contenant des **expériences** (`Experience`) — texte, photo ou vidéo, avec géolocalisation optionnelle. Un carnet peut être publié publiquement et devient alors visible dans le fil d'accueil et la recherche des autres utilisateurs.

## Fonctionnalités

- **Authentification** : email/mot de passe et Google Sign-In (Firebase Auth).
- **Carnets de voyage** : création, édition, publication/dépublication, suppression.
- **Expériences** : texte, photo (caméra ou galerie) ou vidéo (plafonnée à 60s à la capture), avec titre, description et lieu optionnel.
- **Géolocalisation** : position actuelle ou sélection manuelle sur une carte ([OpenStreetMap](https://www.openstreetmap.org), via `flutter_map` — voir [ARCHITECTURE.md](ARCHITECTURE.md#carte)).
- **Accueil et Explorer** : fil des carnets publics (carnet en vedette + liste), recherche par titre et tri (récent/populaire/alphabétique).
- **Hors ligne** : les carnets et expériences de l'utilisateur restent consultables et modifiables sans connexion, avec synchronisation automatique au retour du réseau — voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md).
- **Sécurité** : toutes les règles d'accès aux données sont appliquées côté serveur (Firestore/Storage Security Rules) — voir [SECURITY.md](SECURITY.md).
- **i18n** : interface en français et anglais (`flutter gen-l10n`).

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.41.6 (stable) / Dart ^3.11.4 |
| Architecture | Clean Architecture + Feature-First — voir [ARCHITECTURE.md](ARCHITECTURE.md) |
| Gestion d'état | Riverpod (`flutter_riverpod`), **écrit à la main**, sans codegen |
| Navigation | `go_router` (`StatefulShellRoute.indexedStack`, 5 onglets) |
| Modèles de domaine | `freezed` + `json_serializable` |
| Backend | Firebase — Auth, Firestore, Storage, Analytics, Crashlytics |
| Carte | `flutter_map` (tuiles OpenStreetMap) |
| Stockage local | `sqflite` (cache offline-first + file de mutations) |
| Médias | `image_picker`, `flutter_image_compress`, `video_player`/`chewie`, `video_thumbnail` |

La liste complète des dépendances est dans [pubspec.yaml](pubspec.yaml).

## Structure du projet

```
lib/
  app/                  # Point d'entrée, router (go_router), shell à onglets
  core/                 # Transverse : erreurs, thème, sync, offline, database, utils, widgets partagés
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

Chaque feature suit le même découpage `domain/` (entités, interfaces de repository) → `data/` (sources Firestore/SQLite, implémentations de repository) → `presentation/` (providers/controllers Riverpod, écrans, widgets). Détail complet dans [ARCHITECTURE.md](ARCHITECTURE.md).

## Démarrage

### Prérequis

- Flutter 3.41.6 (stable), Dart ^3.11.4.
- Un projet Firebase avec Auth (Email/Password + Google), Firestore et Storage activés — les fichiers de config (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`) sont déjà commités pour ce projet ; voir [DEPLOYMENT.md](DEPLOYMENT.md) pour pourquoi et comment les régénérer si besoin.

### Installer et lancer

```bash
flutter pub get
flutter gen-l10n              # régénère les traductions si les .arb ont changé (auto au pub get)
dart run build_runner build   # génère les classes @freezed (nécessaire après un checkout frais)
flutter run
```

### Vérifications avant de committer

```bash
dart format .
flutter analyze
flutter test
```

Statut actuel : `flutter analyze` → 0 erreur, `flutter test` → 69 tests verts.

## CI/CD

Un pipeline GitHub Actions (`.github/workflows/ci.yml`) exécute l'analyse, les tests et un build Android de debug à chaque push/PR sur `main`. Détail dans [DEPLOYMENT.md](DEPLOYMENT.md).

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — organisation du code, choix techniques, gestion d'état, navigation.
- [SECURITY.md](SECURITY.md) — modèle de sécurité, règles Firestore/Storage, audit et correctifs appliqués.
- [OFFLINE_SYNC.md](OFFLINE_SYNC.md) — fonctionnement du mode hors ligne et du moteur de synchronisation.
- [DEPLOYMENT.md](DEPLOYMENT.md) — configuration Firebase, CI/CD, builds Android/iOS.

## Limitations connues

- **Firebase Storage n'est pas activé** (nécessite le plan payant Blaze) : l'upload de médias (avatar, couverture, photo/vidéo d'expérience) échoue tant que ce n'est pas fait. Le reste de l'app fonctionne normalement.
- **Pas de job iOS en CI** : nécessiterait un runner macOS et une signature Apple, aucun des deux n'est configuré.
- La carte utilise OpenStreetMap (gratuit, sans clé API) plutôt que Google Maps — choix définitif, voir [ARCHITECTURE.md](ARCHITECTURE.md#carte).

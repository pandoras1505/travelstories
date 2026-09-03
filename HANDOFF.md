# TravelStories — Résumé de reprise

Dernière mise à jour : 2026-09-03, fin de la **Phase 9** (Home Feed + Explore).
Ce fichier existe pour reprendre le projet dans une nouvelle conversation sans perdre le contexte. Il n'est pas un livrable du plan (README/ARCHITECTURE/SECURITY/OFFLINE_SYNC/DEPLOYMENT restent à créer, voir "Dette de documentation" en bas).

---

## 1. Projet en un coup d'œil

- **Nom** : TravelStories — "Transformez vos voyages en histoires."
- **Repo** : `C:\MASTER\Projet Flutter\TravelStories\travelstories`
- **Stack** : Flutter 3.41.6 (stable) / Dart 3.11.4, SDK à `C:\MASTER\flutter_windows_3.41.6-stable\flutter` — **pas dans le PATH système** (voir §6).
- **Architecture** : Clean Architecture + Feature-First (`lib/features/{feature}/{domain,data,presentation}`), state management Riverpod **écrit à la main** (pas de codegen, voir §3).
- **Backend** : Firebase, projet `travelstories-app` (région Firestore/Storage : eur3).
- **Cible** : mobile (Android/iOS) uniquement. `web/` est gardé uniquement comme aide de QA locale (voir §5), pas un livrable.
- **Git** : 12 commits sur `master`, aucun push distant (pas de remote configuré). Identité locale : `botcholi` / `botcholi@gmail.com`.

## 2. Roadmap — statut des 18 phases

| # | Phase | Statut |
|---|---|---|
| 1 | Architecture + Flutter + design system | ✅ |
| 2 | Firebase + Authentication | ✅ |
| 3 | Profile | ✅ |
| 4 | Travel Books CRUD | ✅ |
| 5 | Experiences | ✅ |
| 6 | Camera + Gallery + Storage (pipeline média) | ✅ |
| 7 | Geolocation + Maps | ✅ (Maps = OpenStreetMap, pas Google Maps — voir §4) |
| 8 | Video Player | ✅ |
| 9 | Home Feed + Explore | ✅ |
| 10 | SQLite | ⬜ **prochaine étape** |
| 11 | Offline-first | ⬜ |
| 12 | Synchronization Engine | ⬜ |
| 13 | Security Rules (audit complet) | ⬜ (règles de base déjà écrites et déployées au fil de l'eau, Phase 13 = revue/durcissement) |
| 14 | Tests (suite complète) | ⬜ (tests déjà écrits au fil de l'eau, voir §7) |
| 15 | Performance | ⬜ |
| 16 | CI/CD | ⬜ |
| 17 | Documentation | ⬜ |
| 18 | Production Readiness Review | ⬜ |

## 3. Décisions d'architecture actées

- **Riverpod sans codegen** : `riverpod_generator` entre en conflit de versions (`meta`) avec le SDK Flutter épinglé. Tous les providers sont écrits à la main (`Provider`, `StreamProvider`, `StreamProvider.family`, `AsyncNotifier`/`AsyncNotifierProvider`). Ne pas retenter le codegen sans revérifier cette contrainte.
- **Pattern répété dans chaque feature** : `domain/{entities,repositories,usecases}` → `data/{datasources,repositories}` → `presentation/{providers,controllers,screens,widgets}`. Chaque repository a une interface abstraite + une implémentation Firebase, mappe les exceptions SDK vers la hiérarchie `AppException` (`lib/core/errors/app_exception.dart` : Auth/Network/Firestore/Storage/Database/Location/Media/Sync, chacune avec un `code` optionnel pour le mapping vers des messages localisés).
- **Router** : `appRouterProvider` (Riverpod `Provider<GoRouter>`), pas un singleton global — nécessaire pour rester testable (override d'`authRepositoryProvider` avec un faux repo dans les tests). `redirect` lit `authRepository.currentUser` directement (le router vit hors de l'arbre de widgets).
- **Upload de médias** : pattern uniforme partout (avatar profil, couverture carnet, média expérience) — upload Storage puis mise à jour du document Firestore, jamais l'inverse.
- **Compteur `experienceCount`** : mis à jour de façon atomique via `WriteBatch` Firestore (jamais de lecture-puis-écriture séparée) à la création/suppression d'une expérience.
- **Vidéo** : pas de compression client (packages jugés trop fragiles) — la durée de capture est plafonnée à 60s à la source (`MediaService.maxVideoDuration`). Décision actée dès la Phase 1.
- **Carte** : toute dépendance à un fournisseur de carte est confinée à 2 fichiers (`location_picker_screen.dart`, `experience_map_preview.dart`) — c'est ce qui a permis de swapper Google Maps → OpenStreetMap en quelques minutes sans toucher au reste de l'app (voir §4).
- **Localisation (lieu, pas i18n)** : `latitude`/`longitude` sont optionnels partout — la saisie manuelle du nom de lieu fonctionne sans position GPS ; "utiliser ma position" et "choisir sur la carte" (Phase 7) sont des compléments, pas des prérequis.
- **i18n texte** : fr/en via `flutter gen-l10n`, fichiers sources dans `lib/core/localization/l10n/app_{fr,en}.arb`, généré dans `lib/core/localization/generated/` (gitignored, régénéré à chaque `flutter pub get`/build grâce à `generate: true` dans pubspec.yaml).
- **Tests** : jamais de faux/mocks du SDK Firebase — chaque repository a un *fake* maison en mémoire dans `test/fakes/` implémentant l'interface du domaine (`FakeAuthRepository`, `FakeProfileRepository`, `FakeTravelBookRepository`, `FakeExperienceRepository`). Les tests widgets passent ces fakes via `ProviderScope(overrides: [...])`.

## 4. Contraintes d'environnement découvertes (important, relire avant de perdre du temps à les re-découvrir)

1. **Build Android impossible dans cet environnement** : `flutter run`/`build` échoue systématiquement avec `java.io.IOException: Unable to establish loopback connection` — bug reproduit à l'identique avec JDK 25 et JDK 21 (JBR Android Studio), daemon Gradle activé/désactivé, sandbox Bash activée/désactivée. Cause probable : politique réseau de cette machine gérée (compte AzureAD). **Pas un bug de code.**
2. **`firebase_core_web` cassé sur cette version de Dart** : erreur de compilation `e.isA<JSObject>()` avec Dart 3.11.4 — bug du package, spécifique au web, sans impact sur Android/iOS.
   → Conséquence des deux points ci-dessus : **aucune vérification "live" possible** dans cet environnement pour tout ce qui touche Firebase. Toute la validation s'est faite via `flutter analyze` + `flutter test` (fakes en mémoire) + lecture du code source réel des packages. La Phase 1 (UI pure, sans Firebase) A été vérifiée visuellement via `flutter run -d chrome` (web fonctionne pour de l'UI simple, juste pas avec Firebase importé).
3. **Storage Firebase non activé** : nécessite le plan payant **Blaze** (facturation à l'usage, carte requise même pour rester dans le quota gratuit) depuis fin 2024. L'utilisateur n'a pas de carte disponible → Storage reste non provisionné. Le code d'upload (avatar, couverture, média expérience) est réel et correct, mais échouera à l'exécution tant que Storage n'est pas activé. Rien à faire côté code, juste en attente d'une décision utilisateur.
4. **Google Maps Platform écarté** : nécessite aussi une carte bancaire (même contrainte que Storage). Remplacé par **OpenStreetMap** via `flutter_map` (gratuit, aucune clé API). Décision actée et déployée Phase 7.
5. **`flutter` n'est pas dans le PATH** : toujours préfixer les commandes PowerShell par `$env:Path += ";C:\MASTER\flutter_windows_3.41.6-stable\flutter\bin"`.
6. **Ne jamais `await Future.delayed(...)` dans un corps de `testWidgets`** : l'horloge du binding de test (`flutter_test`) n'avance que via `tester.pump(duration)` — un `Future.delayed` réel reste en attente indéfiniment et bloque le test (repéré Phase 9 : un test seedant deux carnets avec un `Future.delayed(5ms)` entre les deux pour forcer des `createdAt` distincts a fait planter toute la suite pendant ~10 min avant timeout). Pour des timestamps distincts dans un fake, décaler par ordre d'insertion (voir `FakeTravelBookRepository.createTravelBook`), jamais par une vraie pause.
7. **Les listes lazy (`ListView`/`SliverList` dans un `CustomScrollView`) ne construisent que les items visibles dans le viewport de test** (par défaut 800×600) : un `find.text(...)` sur un item plus bas dans une longue liste renvoie `findsNothing` même s'il existe dans les données. Pour un test qui doit voir toute une liste courte sans scroller, agrandir la surface : `tester.view.physicalSize = const Size(800, 2400); tester.view.devicePixelRatio = 1.0;` (+ `addTearDown` pour les deux resets) plutôt que de scroller manuellement.

## 5. État Firebase (projet `travelstories-app`)

- **Auth** : Email/Password + Google activés (par l'utilisateur, Phase 2).
- **Firestore** : base par défaut créée (eur3), règles déployées (`firestore.rules`), index composites déployés (`firestore.indexes.json`, 4 index au total depuis la Phase 9 : `isPublic+createdAt`, `ownerId+updatedAt`, `isPublic+experienceCount+createdAt`, `isPublic+title+createdAt` — ces deux derniers pour le tri "Populaire" et le tri/recherche alphabétique d'Explorer). Schéma : `users/{uid}`, `travelBooks/{id}`, `travelBooks/{id}/experiences/{id}`. Le CLI `firebase` est installé et authentifié dans cet environnement — `firebase deploy --only firestore:indexes` (ou `:rules`) fonctionne normalement, contrairement aux builds Flutter (voir §4.1) : ce n'est pas concerné par la contrainte réseau/Gradle.
- **Storage** : **non activé** (voir §4.3). `storage.rules` écrites mais pas déployées (le déploiement échouera tant que le bucket par défaut n'existe pas — nécessite le clic "Get Started" en console, qui nécessite Blaze).
- **Config apps** : Android (`google-services.json`), iOS (`GoogleService-Info.plist`, placé manuellement — FlutterFire CLI ne peut pas le générer depuis Windows sans Xcode), Web (`firebase_options.dart`, gardé uniquement pour l'aide au QA local).
- **iOS Google Sign-In** : `REVERSED_CLIENT_ID` câblé dans `Info.plist` (`CFBundleURLTypes`).
- **Android Google Sign-In** : nécessitera l'ajout de l'empreinte SHA-1 du keystore (debug puis release) dans la console Firebase avant de fonctionner sur un vrai appareil — pas encore fait (aucun build Android n'a pu être testé, voir §4.1).

## 6. Comment relancer les vérifications

```bash
# Toujours depuis la racine du repo, PowerShell :
$env:Path += ";C:\MASTER\flutter_windows_3.41.6-stable\flutter\bin"
flutter pub get
flutter gen-l10n              # si des clés .arb ont changé
dart run build_runner build   # si une entité @freezed a changé
dart format .
flutter analyze
flutter test
```

Dernier statut connu (fin Phase 9) : `flutter analyze` → 0 issue, `flutter test` → **22/22** tests verts.

## 7. Tests existants

- `test/core/utils/validators_test.dart` — tous les `Validators.*` (email, password, displayName, confirmPassword, title, dateRange).
- `test/widget_test.dart` — redirection auth (signed-out → login ; signed-in → shell avec 5 onglets).
- `test/features/profile/profile_screen_test.dart` — affichage profil → édition → sauvegarde.
- `test/features/travel_books/travel_book_flow_test.dart` — création carnet → détail → liste.
- `test/features/experiences/experience_flow_test.dart` — ajout expérience → édition → suppression (avec dialogue de confirmation).
- `test/features/home/home_feed_test.dart` — feed public (carnet en vedette + liste), un brouillon n'apparaît jamais, jointure auteur affichée.
- `test/features/exploration/explore_screen_test.dart` — recherche par préfixe de titre (filtrage en direct, debounce 350ms), changement de tri sans crash.
- `test/fakes/` — un fake par repository (Auth/Profile/TravelBook/Experience), tous en mémoire, aucun SDK Firebase touché. `FakeTravelBookRepository.fetchPublicTravelBooks` réimplémente tri/filtre/pagination en mémoire (miroir de la logique Firestore réelle) — si la logique de tri/pagination de `TravelBookRepositoryImpl` change, penser à répercuter le changement dans le fake.

Aucun test dédié pour : geolocator/carte (Phase 7) ni video_player (Phase 8) — plugins natifs sans moyen réaliste de les exercer en environnement de test headless. Idem pour toute vérification "live" Firebase (voir §4).

## 8. Dette connue / actions en attente côté utilisateur

- [ ] Activer Firebase Storage (plan Blaze) quand une carte sera disponible → déployer `storage.rules`.
- [ ] Ajouter l'empreinte SHA-1 Android (debug + release) dans la console Firebase pour Google Sign-In.
- [ ] Tester un vrai build Android/iOS sur une machine sans la restriction réseau (§4.1) ou sur un appareil physique.
- [ ] Décider si on reste sur OpenStreetMap définitivement ou si Google Maps sera reconsidéré plus tard (carte bancaire disponible).

## 9. Dette de documentation (Phase 17, pas encore commencée)

Le brief exige `README.md`, `ARCHITECTURE.md`, `SECURITY.md`, `OFFLINE_SYNC.md`, `DEPLOYMENT.md` maintenus en continu. **Aucun n'a été créé pour l'instant** (seul le `README.md` par défaut de `flutter create` existe encore, jamais mis à jour). À faire en Phase 17, ou plus tôt si utile.

## 10. Phase 9 — ce qui a été livré (Home Feed + Explore)

- **Domaine/data** (dans la feature `travel_books`, pas une nouvelle feature — le carnet reste le concept central) : `TravelBookRepository.fetchPublicTravelBooks({sort, titlePrefix, limit, startAfter})` retourne un `PublicTravelBooksPage` (`typedef` record `{books, hasMore}`). Pagination par curseur (dernier `TravelBook` de la page précédente), page = `limit+1` lue en interne pour déterminer `hasMore` sans requête de comptage séparée. `PublicBooksSort` (`recent`/`popular`/`alphabetical`) — forcé à l'ordre alphabétique côté Firestore dès qu'une recherche par préfixe de titre est active (contrainte Firestore : le champ filtré par plage doit être le premier `orderBy`).
- **Accueil** (`features/home`) : `HomeFeedController` (`AsyncNotifier`) — un carnet en vedette (le plus récent) + liste paginée des suivants, `refresh()` (pull-to-refresh) et `loadMore()` (scroll infini, déclenché par un `ScrollController`). Skeleton de chargement fait main (`ShimmerBox`, pas de nouvelle dépendance).
  - **Scope réduit assumé** : pas de "destinations populaires" — le schéma actuel n'a pas de champ lieu sur `TravelBook` (seulement sur `Experience`), et l'agréger en direct via une requête `collectionGroup` aurait été coûteux/fragile pour du MVP. À reconsidérer si une dénormalisation de lieu est ajoutée plus tard.
- **Explorer** (`features/exploration`) : `ExploreController` — recherche (debounce 350ms) + 3 tris (Récent/Populaire/A-Z), pagination identique à l'Accueil. Pas de likes/favoris/commentaires/following (hors scope MVP, confirmé dans le brief).
- **UI partagée** : `PublicTravelBookCard` (`travel_books/presentation/widgets/`) — carte réutilisée par Accueil et Explorer, avec jointure auteur légère (`authorProfileProvider`, `FutureProvider.family` dans `profile_providers.dart`, `ProfileRepository.getProfile(ownerId)`). Toujours pas de dénormalisation auteur sur `TravelBook` — à revoir si les lectures deviennent coûteuses.
- Le carnet public ouvert depuis Accueil/Explorer réutilise `TravelBookDetailScreen` tel quel (déjà capable de masquer les actions d'édition pour un non-propriétaire via `isOwner`) — aucune nouvelle route/écran de détail.
- 2 nouveaux index composites Firestore déployés (voir §5).

## 11. Prochaine étape : Phase 10 — SQLite

Prépare le terrain pour l'offline-first (Phase 11) : schéma SQLite miroir de Firestore pour `travelBooks`/`experiences` (et sans doute une file d'attente de mutations en attente de sync). Pas encore commencée — pas de décision d'architecture actée à ce stade au-delà de ce qui est déjà dans le brief.

---

*Fichier généré à la demande de l'utilisateur pour permettre la reprise du projet dans une nouvelle conversation. Le supprimer ou le mettre à jour librement — ce n'est pas un livrable du plan, juste un aide-mémoire.*

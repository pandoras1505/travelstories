# Revue de mise en production

Bilan final du projet TravelStories (18 phases du roadmap initial), pour répondre à une question simple : **qu'est-ce qui est prêt, et qu'est-ce qui bloque une vraie mise en production ?**

## Verdict

**Prêt pour un usage personnel ou une bêta fermée sur appareil réel — et vérifié comme tel** (voir §27 de `HANDOFF.md`). **Pas encore prêt pour une publication publique sur les stores** — pas pour une raison de qualité de code, mais à cause de décisions externes encore en attente (carte bancaire pour Storage, keystore de release, partage effectif de la politique de confidentialité). Détail ci-dessous.

## 1. Qualité du code

| Point | État |
|---|---|
| `flutter analyze` | ✅ 0 issue |
| `flutter test` | ✅ 69/69 |
| CI (GitHub Actions) | ✅ verte de bout en bout, vérifiée en conditions réelles ([DEPLOYMENT.md](DEPLOYMENT.md)) |
| Logs de debug (`print`/`debugPrint`) résiduels | ✅ aucun trouvé dans `lib/` |
| Gestion des états async (chargement/erreur/vide) | ✅ pattern `.when(loading:, error:, data:)` avec `LoadingView`/`ErrorView`/`EmptyStateView` appliqué systématiquement sur tous les écrans à données async ; les écrans restants (formulaires, splash) n'en ont pas besoin par nature |
| Rapport de crash | ✅ `FirebaseCrashlytics` câblé dans `main.dart` (`FlutterError.onError` + `PlatformDispatcher.instance.onError`) |

## 2. Sécurité

Traité en détail dans [SECURITY.md](SECURITY.md). Résumé :
- Règles Firestore et Storage écrites, durcies (audit Phase 13 : une faille réelle trouvée et corrigée côté Storage), et **déployées pour Firestore** (Storage non déployable tant qu'il n'est pas activé, voir §4).
- Aucune donnée sensible dans un document lisible largement (`email` retiré de `users/{uid}`).
- `google-services.json`/`GoogleService-Info.plist`/`firebase_options.dart` commités par choix — ce sont des clés client, pas des secrets serveur ; aucun `.env`/`.jks`/`.keystore`/`key.properties` n'est suivi par git.
- **Clés API Firebase (`firebase_options.dart`)** : GitHub secret scanning les signale par défaut (pattern `AIza...`). Ce n'est pas une fuite à corriger en régénérant la clé — voir [SECURITY.md](SECURITY.md#à-propos-des-alertes-github-google-api-key) pour la procédure correcte (restreindre chaque clé par app/API dans Google Cloud Console).
- **Non couvert, à noter** : pas de rate-limiting/anti-abus (nécessiterait Cloud Functions), pas de tests automatisés des règles (émulateur Firestore/Storage indisponible dans l'environnement de développement d'origine — les règles n'ont été validées que par relecture).

## 3. Performance

Traité dans [OFFLINE_SYNC.md](OFFLINE_SYNC.md) et le journal de la Phase 15 (`HANDOFF.md` §21). Revue de code ciblée (aucun profiling réel possible, voir §4) : listes déjà lazy, `const` déjà quasi-systématique, jointure auteur déjà mise en cache par Riverpod, batching SQLite déjà en place. Un correctif réel appliqué : taille de cache mémoire des images bornée (`AppImageCache`) plutôt que de décoder chaque image à sa pleine résolution d'upload.

## 4. Préparation à la publication (store) — points **non couverts** par les phases précédentes

Ces points n'étaient pas dans le roadmap initial mais conditionnent une vraie sortie publique :

| Point | État | Action requise |
|---|---|---|
| **Icône de l'app** | ✅ Icône personnalisée générée le 2026-09-04 (pin de voyage, couleurs de la marque — voir §4bis) | Rien à faire |
| **Écran de démarrage (splash)** | ✅ Généré le 2026-09-04, même identité visuelle que l'icône | Rien à faire |
| **Nom affiché sur l'appareil** | ✅ Déjà correct : `"TravelStories"` (`AndroidManifest.xml`, `Info.plist`), pas le nom de package brut |
| **Versioning** | `pubspec.yaml` → `1.0.0+1`, source unique de vérité (Android ne surcharge pas `versionCode`/`versionName` séparément) | Rien à faire, déjà cohérent |
| **`firebase_analytics`** | Dépendance présente dans `pubspec.yaml` mais **jamais utilisée** (aucun `FirebaseAnalytics`/`logEvent` dans `lib/`) | Décision à prendre : la retirer si elle n'est pas prévue, ou l'instrumenter si un suivi d'usage est souhaité — je n'ai rien changé sans te le demander |
| **Politique de confidentialité** | ✅ Rédigée et publiée le 2026-09-04 (voir §4bis) | **Il faut la partager** depuis le menu de partage de l'artefact pour qu'elle soit publiquement accessible — les stores doivent pouvoir l'ouvrir sans compte pour valider la fiche |
| **Textes de permission (iOS)** | ✅ `Info.plist` contient déjà de vrais textes en français pour caméra/photothèque/micro/localisation (pas des placeholders) | Rien à faire |
| **Licence** | Aucun fichier `LICENSE` | Sans objet pour une app privée non publiée sur pub.dev (`publish_to: 'none'`) — à ajouter seulement si le code doit un jour être rendu public/open source |

### 4bis. Icône, splash et politique de confidentialité (2026-09-04)

- **Icône** : un pin de voyage (cercle + pointe, comme un repère de carte) en teal (`AppColors.tealLight` `#3F9A96`) sur le fond sombre de l'app (`AppColors.neutral900` `#1A1613`) — cohérent avec l'identité visuelle existante plutôt qu'un logo arbitraire. Sources dans `assets/icon/` (`icon.png` plein, `icon_background.png`/`icon_foreground.png` pour les icônes adaptatives Android). Générée via `flutter_launcher_icons` (config dans `pubspec.yaml`) — régénérer avec `dart run flutter_launcher_icons` après modification des sources.
- **Splash** : même fond sombre + le pin en transparence, via `flutter_native_splash` (config dans `pubspec.yaml`) — régénérer avec `dart run flutter_native_splash:create`.
- **Politique de confidentialité** : rédigée en français, couvre les données réellement traitées par l'app (compte, contenu des carnets, position optionnelle, diagnostics Crashlytics, stockage local des médias — voir `OFFLINE_SYNC.md`), publiée en artefact. **Reste privée tant qu'elle n'est pas partagée** depuis le menu de partage de l'artefact — nécessaire pour que les stores puissent l'ouvrir sans compte lors de la validation de la fiche.

## 5. Dette et bloquants connus (rappel de `HANDOFF.md` §8)

| Bloquant | Cause | Statut |
|---|---|---|
| Firebase Storage non activé | Nécessite le plan Blaze (carte bancaire) | **Décision confirmée** : reste désactivé — contourné par un stockage local des médias (voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md#médias--stockage-local-en-attendant-storage)). L'upload fonctionne donc à nouveau pour un usage sur un seul appareil, mais un carnet publié ne montre ses médias qu'à son propriétaire sur cet appareil — **nouveau bloquant pour une publication store** tant que ça reste le cas, puisque le partage public de photos/vidéos ne fonctionnerait pas pour les autres utilisateurs |
| Empreinte SHA-1 release manquante | Aucun keystore de release créé | En attente — voir [DEPLOYMENT.md](DEPLOYMENT.md) pour la procédure quand tu seras prêt |
| Build Android réel jamais testé | Restriction réseau de la machine de développement (voir `HANDOFF.md` §4.1) | **✅ Testé le 2026-09-04** — APK debug de la CI installé via `adb` sur un vrai téléphone Android, app fonctionnelle de bout en bout (voir `HANDOFF.md` §27). Un vrai bug de synchronisation a été trouvé et corrigé à cette occasion. iOS reste non testé (aucun appareil/Mac disponible) |
| Carte OpenStreetMap vs Google Maps | Carte bancaire indisponible pour Google Maps Platform | **Décision confirmée définitive** : OpenStreetMap |

## 6. Checklist finale

- [x] Code : analyse et tests verts, CI fonctionnelle et vérifiée en conditions réelles
- [x] Sécurité : règles écrites, auditées, déployées (Firestore) ; secrets hygiéniques
- [x] Performance : revue faite, un correctif réel appliqué
- [x] Documentation : les 5 fichiers requis existent et sont à jour
- [x] Gestion d'erreurs et rapport de crash en place
- [x] Upload de médias fonctionnel (stockage local en attendant Storage — usage un seul appareil uniquement, voir ci-dessus)
- [x] Image de marque (icône, splash) personnalisée
- [x] Build Android réel testé sur un appareil physique — voir `HANDOFF.md` §27
- [ ] Politique de confidentialité **rédigée mais à partager publiquement** (menu de partage de l'artefact — voir §4)
- [ ] Décision sur `firebase_analytics` (retirer ou instrumenter)
- [ ] Storage activé (nécessaire pour que le partage public de médias fonctionne pour les autres utilisateurs, pas pour l'upload en lui-même)
- [ ] Keystore de release + empreinte SHA-1 associée
- [ ] Clés API Firebase restreintes par app/API dans Google Cloud Console (voir [SECURITY.md](SECURITY.md#à-propos-des-alertes-github-google-api-key))

## Conclusion

Le code, l'architecture, la sécurité, les tests et le pipeline CI sont au niveau attendu pour une mise en production — rien dans les 17 phases précédentes ne bloque techniquement une sortie. Ce qui reste ouvert relève de **décisions produit/business et d'actifs graphiques** que je ne peux pas trancher ou produire à ta place : activer Storage, créer un keystore de release, dessiner une icône, rédiger une politique de confidentialité, et tester sur un vrai appareil. Le roadmap des 18 phases est terminé.

# Revue de mise en production

Bilan final du projet TravelStories (18 phases du roadmap initial), pour répondre à une question simple : **qu'est-ce qui est prêt, et qu'est-ce qui bloque une vraie mise en production ?**

## Verdict

**Prêt pour un usage personnel ou une bêta fermée sur appareil réel.** **Pas prêt pour une publication publique sur les stores** — pas pour une raison de qualité de code, mais à cause de décisions externes encore en attente (carte bancaire pour Storage, keystore de release, image de marque). Détail ci-dessous.

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
| **Icône de l'app** | Icône par défaut de `flutter create` (Android et iOS), pas d'image de marque personnalisée | Fournir une icône (ex. via `flutter_launcher_icons`) avant toute publication — nécessite un visuel que je ne peux pas inventer à ta place |
| **Écran de démarrage (splash)** | Template par défaut (fond blanc, pas de logo) | Idem — personnalisation graphique à faire |
| **Nom affiché sur l'appareil** | ✅ Déjà correct : `"TravelStories"` (`AndroidManifest.xml`, `Info.plist`), pas le nom de package brut |
| **Versioning** | `pubspec.yaml` → `1.0.0+1`, source unique de vérité (Android ne surcharge pas `versionCode`/`versionName` séparément) | Rien à faire, déjà cohérent |
| **`firebase_analytics`** | Dépendance présente dans `pubspec.yaml` mais **jamais utilisée** (aucun `FirebaseAnalytics`/`logEvent` dans `lib/`) | Décision à prendre : la retirer si elle n'est pas prévue, ou l'instrumenter si un suivi d'usage est souhaité — je n'ai rien changé sans te le demander |
| **Politique de confidentialité** | Aucun fichier `PRIVACY`/`terms` dans le dépôt | **Obligatoire pour publier sur le Play Store et l'App Store** dès qu'une app collecte position, photos/vidéos ou identifiants (Google Sign-In, Crashlytics) — nécessite une page publique (URL) et le remplissage du formulaire "Sécurité des données" de chaque store. Document légal — je peux t'aider à en rédiger un brouillon si tu le demandes explicitement, mais je ne l'ai pas fait de ma propre initiative |
| **Textes de permission (iOS)** | ✅ `Info.plist` contient déjà de vrais textes en français pour caméra/photothèque/micro/localisation (pas des placeholders) | Rien à faire |
| **Licence** | Aucun fichier `LICENSE` | Sans objet pour une app privée non publiée sur pub.dev (`publish_to: 'none'`) — à ajouter seulement si le code doit un jour être rendu public/open source |

## 5. Dette et bloquants connus (rappel de `HANDOFF.md` §8)

| Bloquant | Cause | Statut |
|---|---|---|
| Firebase Storage non activé | Nécessite le plan Blaze (carte bancaire) | **Décision confirmée** : reste désactivé — contourné par un stockage local des médias (voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md#médias--stockage-local-en-attendant-storage)). L'upload fonctionne donc à nouveau pour un usage sur un seul appareil, mais un carnet publié ne montre ses médias qu'à son propriétaire sur cet appareil — **nouveau bloquant pour une publication store** tant que ça reste le cas, puisque le partage public de photos/vidéos ne fonctionnerait pas pour les autres utilisateurs |
| Empreinte SHA-1 release manquante | Aucun keystore de release créé | En attente — voir [DEPLOYMENT.md](DEPLOYMENT.md) pour la procédure quand tu seras prêt |
| Aucun build Android/iOS réel testé | Restriction réseau de la machine de développement (voir `HANDOFF.md` §4.1) | À tester sur un appareil physique ou une autre machine — la CI GitHub Actions a produit un APK debug qui s'est buildé avec succès, c'est la meilleure preuve indirecte obtenue à ce jour |
| Carte OpenStreetMap vs Google Maps | Carte bancaire indisponible pour Google Maps Platform | **Décision confirmée définitive** : OpenStreetMap |

## 6. Checklist finale

- [x] Code : analyse et tests verts, CI fonctionnelle et vérifiée en conditions réelles
- [x] Sécurité : règles écrites, auditées, déployées (Firestore) ; secrets hygiéniques
- [x] Performance : revue faite, un correctif réel appliqué
- [x] Documentation : les 5 fichiers requis existent et sont à jour
- [x] Gestion d'erreurs et rapport de crash en place
- [x] Upload de médias fonctionnel (stockage local en attendant Storage — usage un seul appareil uniquement, voir ci-dessus)
- [ ] Image de marque (icône, splash) personnalisée
- [ ] Politique de confidentialité publiée (obligatoire pour les stores)
- [ ] Décision sur `firebase_analytics` (retirer ou instrumenter)
- [ ] Storage activé (nécessaire pour que le partage public de médias fonctionne pour les autres utilisateurs, pas pour l'upload en lui-même)
- [ ] Keystore de release + empreinte SHA-1 associée
- [ ] Build réel testé sur un appareil physique
- [ ] Clés API Firebase restreintes par app/API dans Google Cloud Console (voir [SECURITY.md](SECURITY.md#à-propos-des-alertes-github-google-api-key))

## Conclusion

Le code, l'architecture, la sécurité, les tests et le pipeline CI sont au niveau attendu pour une mise en production — rien dans les 17 phases précédentes ne bloque techniquement une sortie. Ce qui reste ouvert relève de **décisions produit/business et d'actifs graphiques** que je ne peux pas trancher ou produire à ta place : activer Storage, créer un keystore de release, dessiner une icône, rédiger une politique de confidentialité, et tester sur un vrai appareil. Le roadmap des 18 phases est terminé.

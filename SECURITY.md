# Sécurité

TravelStories n'a pas de backend applicatif propre : tout le contrôle d'accès aux données est appliqué par les **Firestore et Storage Security Rules**, exécutées côté serveur par Firebase. Le client (l'app Flutter) n'est jamais la source de vérité pour une autorisation — un appel direct à l'API Firestore/Storage (hors app) est soumis exactement aux mêmes règles.

## Modèle de données et règles Firestore (`firestore.rules`)

### `users/{uid}`

- **Lecture** : autorisée pour tout utilisateur connecté (`isSignedIn()`), pas seulement le propriétaire — nécessaire pour la jointure auteur affichée sur les cartes de carnets publics (Accueil/Explorer).
- **Écriture** : uniquement par le propriétaire (`isOwner(uid)`), et **le champ `email` est explicitement interdit** (`!('email' in request.resource.data.keys())`).
- **Suppression** : jamais autorisée.

> Ce document étant lisible par n'importe quel utilisateur connecté, il ne doit **jamais** contenir de donnée sensible. L'email de l'utilisateur courant est lu depuis `AuthUser` (Firebase Auth, déjà disponible côté client) plutôt que dupliqué ici — voir l'audit ci-dessous.

### `travelBooks/{id}`

- **Lecture** : le carnet doit être `isPublic == true`, ou l'appelant doit en être le propriétaire.
- **Création** : l'appelant doit être connecté et déclaré comme `ownerId`.
- **Mise à jour** : réservée au propriétaire. `ownerId` et `createdAt` sont **immuables** une fois posés. `experienceCount` ne peut varier que de **±1** par écriture et ne peut jamais devenir négatif — empêche un propriétaire de faire artificiellement passer son carnet pour plus "populaire" ou plus "récent" via un appel direct à l'API (ces deux champs pilotent le tri d'Explorer).
- `title` (1-120 caractères), `description` (≤ 10 000 caractères), `startDate`/`endDate` (timestamp ou `null`) sont validés à la création **et** à la mise à jour.
- **Suppression** : réservée au propriétaire.

### `travelBooks/{id}/experiences/{experienceId}`

- **Lecture** : héritée du carnet parent (`parentBook().isPublic == true` ou propriétaire du carnet).
- **Création/mise à jour** : réservées au propriétaire du carnet parent. `travelBookId`, `ownerId` et `createdAt` sont immuables une fois posés (déplacer une expérience vers un autre carnet n'est pas une fonctionnalité de l'app, donc aucune raison légitime de les modifier).
- Champs validés : `title` (1-120), `description` (≤ 10 000), `latitude`/`longitude` (bornes géographiques valides ou `null`), `locationName` (≤ 200 caractères ou `null`), `mediaType` (`'text' | 'image' | 'video'`).

## Règles Storage (`storage.rules`)

| Chemin | Lecture | Écriture / suppression |
|---|---|---|
| `users/{uid}/profile/*` | publique | propriétaire uniquement, image valide (`image/*`, < 15 Mo) |
| `travelBooks/{id}/cover/*` | publique | propriétaire du carnet uniquement |
| `travelBooks/{id}/experiences/{expId}/*` | publique | propriétaire du carnet uniquement, image ou vidéo valide (< 15 Mo / < 200 Mo) |

Les lectures sont publiques par choix : le contrôle "carnet public ou privé" est appliqué côté Firestore (un client n'obtient l'URL d'un média que via un document Firestore déjà filtré par les règles ci-dessus), pas côté Storage.

La vérification de propriété pour un chemin `travelBooks/{travelBookId}/...` se fait par un appel croisé vers Firestore depuis les règles Storage :

```
function isTravelBookOwner(travelBookId) {
  return isSignedIn()
    && firestore.get(/databases/(default)/documents/travelBooks/$(travelBookId)).data.ownerId
      == request.auth.uid;
}
```

## Audit de sécurité (historique)

Une relecture complète des deux fichiers de règles a été menée contre ce que le code écrit réellement. Un problème réel a été trouvé et corrigé :

- **Faille corrigée — écriture/suppression Storage sans vérification de propriété.** La version initiale de `storage.rules` n'exigeait qu'`isSignedIn()` pour écrire ou supprimer la couverture d'un carnet ou le média d'une expérience — n'importe quel utilisateur connecté pouvait donc écraser ou supprimer un fichier appartenant à quelqu'un d'autre. Corrigé avec `isTravelBookOwner()` ci-dessus.
- **`users/{uid}` ne stocke plus `email`** — c'était le seul champ réellement sensible exposé à tout utilisateur connecté via la règle de lecture large ; retiré du modèle de domaine `UserProfile`, l'app lit l'email depuis `AuthUser` à la place.
- **Champs immuables et bornes numériques** ajoutés sur `travelBooks`/`experiences` (voir ci-dessus) — absents de la première version des règles.
- **Validation harmonisée entre `create` et `update`** — avant l'audit, la règle `update` des expériences ne revalidait presque rien, contrairement à `create` (un `update` direct hors app aurait pu poser un titre vide ou surdimensionné).

## Hors du périmètre actuel

- **Pas de limite de taux / anti-abus** : Firestore et Storage n'offrent pas de rate-limiting natif dans les règles elles-mêmes ; ce serait un sujet Cloud Functions, non traité pour l'instant.
- **Pas de résolution de conflits multi-appareils** au niveau des données — voir [OFFLINE_SYNC.md](OFFLINE_SYNC.md).

## Bonnes pratiques côté client

- Aucun message ou code d'erreur brut du SDK Firebase n'atteint l'utilisateur : chaque implémentation de repository mappe les exceptions natives vers la hiérarchie `AppException` (`lib/core/errors/app_exception.dart`), et des fonctions dédiées par domaine traduisent le `code` optionnel en message localisé.
- `google-services.json`, `GoogleService-Info.plist` et `firebase_options.dart` sont commités dans le dépôt : ce sont des clés client publiques (identifient l'app auprès de Firebase), pas des secrets serveur — la vraie protection vient des Security Rules ci-dessus, pas du secret de ces fichiers. Voir [DEPLOYMENT.md](DEPLOYMENT.md).

## Déployer et vérifier les règles

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage    # une fois Storage activé (plan Blaze)
```

Aucun test exécutable (`@firebase/rules-unit-testing` contre l'émulateur Firestore/Storage) n'a pu être mis en place dans l'environnement de développement d'origine de ce projet (l'émulateur ne démarre pas sur cette machine). Les règles ont donc été validées par relecture attentive et cohérence avec ce que le code écrit réellement, pas par une suite de tests automatisée — un point à corriger si l'environnement le permet un jour.

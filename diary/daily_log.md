# 📓 Journal de Développement - HMI Stars (Plateforme & Mobile)

---

## 📅 22 Mai 2026 - Intégration du Module Congés & Stabilisation

### ✅ Fait :
- **Mobile (`hmistarsmobile`) :**
  - **Routage du Module Congés** : Intégration de la page `CongesPage` dans le système de routage GoRouter sous la route `/conges` dans le Shell de navigation principal.
  - **Dashboard Dynamique** : Remplacement des absences statiques par un calcul dynamique en temps réel (`congesAujourdhui`) qui compte le nombre d'employés ayant un congé approuvé en cours aujourd'hui.
  - **KPIs Interactifs** : Ajout d'une callback `onTap` aux widgets de cartes KPI (`_buildKPICard`) pour permettre la navigation directe depuis la carte **Absences** vers la page de gestion des congés.
  - **Bento de Raccourcis Rapides** : Extension de la grille d'actions rapides du tableau de bord de 4 à 6 raccourcis, en ajoutant **Congés & Abs.** et **Messagerie** pour une meilleure symétrie visuelle (grille 2x3) et une ergonomie accrue.
  - **Résolution des Erreurs de Compilation** : Correction des arguments requis manquants (`nomDeNaissance`, `typeContrat`) dans le constructeur de repli pour `Salarie` utilisé dans `conges_page.dart`, ce qui a permis de compiler l'application avec succès en mode Release.

- **Base de données (Supabase) :**
  - **Documentation du Schéma** : Analyse et synchronisation complète de la structure de la base de données live Supabase avec le fichier local `database_schema.sql`, y compris la table `conges`, RLS et les triggers.

---

## 📅 19 Mai 2026 - Restauration & Améliorations de la Messagerie (Plateforme Web)

### ✅ Fait :
- **Plateforme Web (`Platforme`) :**
  - **Indicateur Visuel de Message Non Lu (Point Rouge)** : Restauration et amélioration du point rouge de notification sur l'icône de messagerie dans la barre latérale globale (`AppSidebar`). Le point rouge est rendu en superposition (Stack) et s'affiche uniquement s'il y a des messages non lus provenant d'une quelconque entreprise. Il disparaît instantanément dès que l'administrateur ouvre ou sélectionne la conversation de cette entreprise.
  - **Filtre de Messages (Tous vs Favoris)** : Implémentation d'un onglet de bascule au sommet de la barre latérale de messagerie permettant de basculer entre la liste de toutes les conversations actives ("Tous") et la liste des entreprises épinglées ("Favoris"). Le statut de favori est persisté localement sur l'appareil à l'aide de `SharedPreferences`.
  - **Gestion des Favoris** : Ajout d'une option d'action dynamique (Bouton d'étoile) dans le panneau de détails de l'entreprise (à droite de l'écran de chat) pour marquer ou retirer une entreprise des favoris, ce qui actualise instantanément le filtre.
  - **Téléversement et Réception de Fichiers & Médias** : Ajout de boutons d'action (trombone pour les fichiers génériques et icône d'image pour les images) à côté du champ de saisie du chat. L'administrateur peut maintenant sélectionner n'importe quel type de document ou d'image grâce à `FilePicker.pickFiles`, qui est téléversé en temps réel vers le bucket public `documents` de Supabase et envoyé instantanément en tant que message de fichier dans la conversation.
  - **Cloche de Notification Fonctionnelle** : Intégration de la cloche de notification interactive (`AppTopBar` / `NotificationProvider`) connectée au flux de données en temps réel (Real-time Stream Supabase) pour capter instantanément tout document ou fichier envoyé par un client depuis l'application mobile. Le badge de notification numérique rouge se met à jour en temps réel. Cliquer sur un document dans le menu de la cloche de notification l'affiche comme lu, sélectionne automatiquement l'entreprise correspondante et redirige l'utilisateur vers sa messagerie.

---

## 📅 18 Mai 2026 - Amélioration UX Fichiers & Nettoyage de Code (Plateforme & Mobile)

### ✅ Fait :
- **Plateforme Web (`Platforme`) :**
  - **Aperçu Image Premium (Lightbox)** : Implémentation d'une visionneuse d'images plein écran moderne. Utilise un effet de flou artistique en arrière-plan (`BackdropFilter` et `ImageFilter.blur`) avec un composant de zoom interactif (`InteractiveViewer`) permettant de manipuler (pan, zoom tactile) les images dans le même onglet de manière intuitive et esthétique.
  - **Gestion des Fichiers Non-Images** : Séparation stricte de la logique. Les fichiers qui ne sont pas des images (ex: PDF, CSV, Excel) se téléchargent désormais directement sur l'appareil pour être ouverts par les outils système natifs du client.
  - **Nettoyage de Nommage (Pas d'Underscores)** : Renommage complet de la méthode privée de helper `_typeLabel` en `getTypeLabel` pour bannir complètement l'usage d'underscores en début/fin de nom.
  - **Gestion Multi-fichiers** : Mise à jour de `MessagerieProvider` (`envoyerFichiersMultiples`) et de `FilePicker` pour uploader séquentiellement plusieurs fichiers. Les URLs et noms sont concaténés par des virgules dans Supabase.
  - **Rendu Multi-fichiers** : Ajout de la méthode `_buildFichiers` dans la bulle de message pour itérer sur les fichiers concaténés et les afficher un par un.

- **Mobile (`hmistarsmobile`) :**
  - **Visionneuse Image Interne Premium (Lightbox)** : Implémentation d'une boîte de dialogue plein écran interactive directement au sein de l'application mobile lors du clic sur une image (ou lors de la sélection de l'option "Ouvrir le fichier" pour une image). L'image s'ouvre avec un filtre de flou d'arrière-plan (`BackdropFilter` et `ImageFilter.blur`) et un composant de zoom interactif (`InteractiveViewer`), évitant ainsi d'ouvrir le navigateur web externe.
  - **Ouverture Directe des Fichiers Non-Images** : Modification de la messagerie mobile pour contourner le contrôle restrictif de `canLaunchUrl` qui renvoyait silencieusement `false` sous Android 11+. Les documents non-images se lancent directement avec les applications par défaut du système dans un bloc try-catch.
  - **Nettoyage de Nommage (Pas d'Underscores)** : Suppression méthodique de tous les underscores initiaux ou finaux de toutes les méthodes et variables privées au sein de `message_bubble.dart` (ex: `_isImage` -> `isImage`, `_onFileTap` -> `onFileTap`, `_getNumberWord` -> `getNumberWord`, `_buildFileBubble` -> `buildFileBubble`, `_buildTextBubble` -> `buildTextBubble`, `_formatTime` -> `formatTime`, `_buildImageThumbnail` -> `buildImageThumbnail`, `_typeLabel` -> `getTypeLabel`).
  - **Gestion Multi-fichiers** : Refonte de `MessageBubble` pour diviser les URLs/noms par virgules et afficher individuellement les différents fichiers et images de la liste envoyée.
  - **Sélection et Upload Multiples** : Modification du `FilePicker` et mise à jour de `AppState.addMessage` pour prendre en charge l'upload en boucle des fichiers multiples avant l'envoi du message.

- **Général (Normes de Développement) :**
  - Respect scrupuleux des consignes du client : Commentaires, variables et textes d'interface rédigés strictement en français, et interdiction d'employer des underscores au début ou à la fin de toute déclaration.

### 💡 Justification Technique & Origine de la Connaissance (Pour le Jury) :
- **Origine du problème d'ouverture externe** : Auparavant, l'ouverture de n'importe quel fichier déléguait l'affichage au système hôte via `url_launcher`. Pour les images, cela forçait le lancement du navigateur externe (ex: Safari ou Chrome), créant une rupture majeure dans le parcours utilisateur. De plus, sur Android 11+ (API 30+), la sécurité renforcée restreint la visibilité des applications externes. Sans déclarer les intentions dans la section `<queries>` de l'AndroidManifest, `canLaunchUrl` renvoyait silencieusement `false`, bloquant toute action.
- **Résolution Interne Établie (Frosted Lightbox)** :
  1. **Boîte de dialogue native** : Remplacement des processus système externes par une superposition locale (`showDialog` et `Dialog` transparent).
  2. **Profondeur Visuelle** : Combinaison de `BackdropFilter` et de `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` sur une superposition noire semi-opaque (90%) pour flouter artistiquement le chat en arrière-plan et sublimer l'image.
  3. **Interaction Native** : Intégration de l'image dans un `InteractiveViewer` supportant le pinch-to-zoom (jusqu'à 5.0x) et le glissement libre (pan) géré à 100% au sein du même layout applicatif.
- **Ressources Documentaires de Référence Utilisées** :
  - *Android 11 Package Visibility Restrictions* : https://developer.android.com/about/versions/11/privacy/package-visibility
  - *Flutter InteractiveViewer API Reference* : https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html
  - *Flutter BackdropFilter (Flou Visuel) API Reference* : https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html
  - *Flutter Dialogs Material API* : https://api.flutter.dev/flutter/material/showDialog.html

---

## 📅 14 Mai 2026 - Maintenance Environnement & Build

### ✅ Fait :
- **Général :**
  - Résolution des erreurs de version SDK Dart (`^3.11.3` mismatch) dans les deux projets (`hmistarsmobile` et `Platforme`) en abaissant la contrainte à `^3.6.0` pour assurer la compatibilité avec le SDK local (3.9.2).
  - **Maintenance NDK** : Suppression forcée du répertoire NDK corrompu (`27.0.12077973`) qui bloquait le build release suite à des échecs de téléchargement réseau.
  - Nettoyage final de l'espace de travail (suppression des dossiers temporaires et doublons).

- **Messagerie (Mobile & Plateforme) :**
  - Implémentation du **Lazy Loading (Pagination)** : chargement des messages par blocs de 20 pour optimiser les performances sur les longues conversations.
  - Fix critique du bug de l'aperçu dans la sidebar : affiche désormais strictement le **dernier message** reçu ou envoyé grâce à un verrou de protection "Strictly Newer" (évite le retour au premier message "hi" lors de l'initialisation du stream).
  - **Indicateur de Messages Non Lus** : Mise en gras (**Bold**) automatique des noms d'entreprises ayant des nouveaux messages non consultés par l'administrateur.
  - Standardisation de la gestion des dates : conversion systématique en heure locale (`toLocal()`) pour garantir un tri chronologique parfait entre le Web et le Mobile.
  - **Réactivité Sidebar** : Ajout d'un tri dynamique automatique qui fait remonter les conversations actives en haut de la liste dès réception d'un message.
  - Ajout d'indicateurs de chargement (spinners) lors de la récupération des messages historiques.
  - Support du défilement infini bidirectionnel (Temps réel + Historique).
- **Plateforme Web (`Platforme`) :**
  - **Correction du chargement initial** : Résolution du bug où les entreprises ne s'affichaient pas sans un double rafraîchissement (Refresh). Ajout du déclenchement automatique du fetch dans le `DashboardPage` et renforcement de la synchronisation entre `EntrepriseProvider` et `MessagerieProvider`.
  - **Amélioration UX** : Suppression de la bordure bleue de focus sur le champ de saisie des messages.
  - **Raccourci clavier** : Envoi de message activé via la touche **Entrée** (TextInputAction.send).
  - **Scroll automatique** : Défilement fluide vers le bas lors de l'envoi d'un nouveau message.
  - **Design Premium** : Mise à jour des bulles de messages avec des dégradés (`primaryGradient`) et des ombres portées.
- **Documentation :**
  - Mise à jour de `ARCHITECTURAL_JUSTIFICATION.md` avec les détails sur la synchronisation "Strictly Newer" et l'isolation RLS.
  - Mise à jour de `NEXT_STEPS.md` avec la feuille de route pour FCM et l'IA.

---

## 📅 13 Mai 2026 - Amélioration UX et Résolution de Bugs (Mobile & Plateforme)

### ✅ Fait :
- **Mobile (`hmistarsmobile`) :**
  - Ajout du bouton "Actualiser" dans l'interface des salariés pour synchroniser manuellement avec la plateforme.
  - Ajout du bouton "Tout cocher" dans la liste de pointage journalier pour faciliter la validation de présence de plusieurs salariés d'un coup.
  - Fix de la contamination de session croisée (vidage du cache et déconnexion forcée via `await _authService.signOut()` dans `AppState.login()`).
  - Intégration de la fonctionnalité de suppression définitive des salariés (parité avec le web).
  - Ajout des permissions `INTERNET` et `ACCESS_NETWORK_STATE` dans `AndroidManifest.xml` pour corriger les erreurs `SocketException` en release.
  - Vérification de la logique de pointage : suppression des données simulées, l'application est bien câblée au backend Supabase.
- **Plateforme Web (`Platforme`) :**
  - Ajout d'un bouton "Désarchiver" (`unarchive_outlined`) dans la liste des employés archivés pour restaurer un salarié.

---

## 📅 12 Mai 2026 - Stabilisation Auth (Plateforme) & Mise à jour Mobile

### ✅ Fait :
- **Plateforme Web (`Platforme`) :**
  - Correction de l'écrasement des données dans les paramètres de la plateforme.
  - Rendre la page `SettingsPage` réactive à l'état de l'utilisateur avec `didChangeDependencies`.
  - Ajout du champ *Téléphone* dans la page d'inscription (`sign_up_page.dart`).
  - Mise à jour de `AuthProvider` et `PlatformAuthService` pour capturer le téléphone.
  - Modification du déclencheur SQL (`creer_profil_plateforme`) pour injecter le téléphone et l'organisation dans la base de données.
  - Résolution de l'erreur SMTP 500 (`Error sending confirmation email`) en configurant un App Password valide dans Supabase.
  - Résolution de l'erreur 429 (`over_email_send_rate_limit`) en nettoyant le code de debug qui doublait les appels.
  - Résolution du crash sur la route `/` en ajoutant `onGenerateRoute` et `onUnknownRoute` dans `main.dart`.
  - Ajout d'un dialogue de re-confirmation de l'e-mail avec l'option de renvoyer le code si l'email n'est pas encore confirmé lors de la connexion.
  - Confirmation manuelle de l'email de test `ibdellihassen6@gmail.com` et correction des métadonnées utilisateur via SQL.

- **Mobile (`hmistarsmobile`) :**
  - Mise à jour de l'URL Supabase et de l'Anon Key vers la base de production (`zzasqztvviakcggfxoud.supabase.co`).
  - Suppression des références à la table `entreprise_users` obsolète.
  - Renommage des colonnes : `is_archived` en `est_archive` et booléens de pièces jointes (de `has_*` vers `a_*`).
  - Renommage de la table `avertissement_templates` vers `modeles_avertissements`.
  - Ajout de la politique RLS `client_update_propre_entreprise` permettant aux clients de modifier les informations de leur propre entreprise.

### ⏳ À faire / En cours :
- **Profil utilisateur** : Vérifier que le trigger `creer_profil_plateforme` crée correctement le profil avec tous les champs (nom, téléphone, cin, organisation).
- **Photo de profil** : UI prête, logique de mise à jour de la base de données/storage manquante.

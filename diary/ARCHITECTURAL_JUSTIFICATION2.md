# Justification Architecturale - Système de Messagerie HMI Stars

Ce document présente les choix techniques effectués pour le système de messagerie de la solution HMI Stars, destinés à être présentés au jury.

## 1. Choix de la Structure de la Base de Données

### Pourquoi une table unique (`messages`) ?
Contrairement à une approche où l'on créerait une table par entreprise (difficile à maintenir et non scalable), nous avons opté pour une architecture **Multi-tenant** basée sur une table unique :
- **Isolation des Données** : Utilisation du **Row Level Security (RLS)** de PostgreSQL/Supabase. Chaque entreprise ne peut lire que ses propres messages via des politiques de sécurité strictes basées sur l'ID de l'entreprise.
- **Performance** : Utilisation d'index B-Tree composites sur `(entreprise_id, date_envoi)`. Cela garantit des recherches en temps constant ou logarithmique, même avec des millions de messages.
- **Maintenance** : Un seul schéma à maintenir, facilitant les migrations et les mises à jour globales.

## 2. Scalabilité et Performance

### Lazy Loading (Pagination)
Pour éviter de saturer la mémoire du navigateur ou du smartphone, nous avons implémenté un système de **Lazy Loading** :
- **Chargement par blocs** : Seuls les 20 messages les plus récents sont chargés initialement.
- **Récupération à la demande** : Les messages plus anciens sont récupérés dynamiquement lorsque l'utilisateur scrolle vers le haut de la conversation.
- **Réduction du trafic réseau** : Cela minimise la consommation de données mobiles et accélère le temps de premier rendu.

### Real-time (Temps Réel)
Le système utilise les **WebSockets (Supabase Streams)** pour une synchronisation instantanée :
- **Optimistic UI** : Les messages apparaissent instantanément pour l'expéditeur avant même la confirmation du serveur, offrant une sensation de fluidité extrême.
- **Bidirectionnalité** : La plateforme Admin et l'application mobile reçoivent les mises à jour en moins de 100ms.

## 3. Synchronisation Temporelle
Nous avons résolu les problèmes de fuseaux horaires (Timezones) en appliquant le standard **UTC-first** :
- **Stockage en UTC** : Toutes les dates sont stockées sans décalage dans la base de données.
- **Conversion au rendu** : La conversion en heure locale n'est effectuée qu'au dernier moment, dans l'interface utilisateur, garantissant l'exactitude des horaires quel que soit le lieu de consultation.

## 4. Perspectives d'Évolution
L'architecture est prête pour :
1. **Partitionnement de Table** : Si le volume dépasse 100 millions de messages, PostgreSQL peut diviser physiquement la table sans changer le code.
2. **Notifications Push** : Intégration prévue via Firebase Cloud Messaging (FCM).
3. **Audit & Conformité** : Historique immuable permettant un suivi légal des échanges.

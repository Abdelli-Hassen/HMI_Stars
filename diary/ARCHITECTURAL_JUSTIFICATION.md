# HMI Stars - Note d'Architecture (À l'attention du Jury)
**Sujet**: Évolutivité de la base de données et Gestion de la Multi-ténance (Multi-tenancy)

---

### 🏛️ Le Choix de l'Architecture "Single-Table"
Lors de la conception du système de messagerie, nous avons opté pour une structure de table unique pour tous les messages de toutes les entreprises. Ce choix repose sur trois piliers industriels :

1.  **Optimisation par Indexation Composite** : 
    *   Nous n'utilisons pas une recherche séquentielle. Nous avons implémenté des **Index B-Tree** sur les colonnes `entreprise_id` et `date_envoi`.
    *   *Impact*: La complexité de recherche reste en **O(log n)**. Même avec 1 million de messages, le système identifie les messages d'une entreprise spécifique en quelques millisecondes.
2.  **Scalabilité par Partitionnement Déclaratif** :
    *   Le système est conçu pour évoluer sans modification de code. Si le volume dépasse les seuils critiques, PostgreSQL nous permet d'activer le **Partitionnement**. La table est alors scindée physiquement (par exemple par mois ou par ID) tout en restant une seule entité logique pour l'application Flutter.
3.  **Maintenabilité et Agilité** :
    *   Une table unique facilite les mises à jour de schéma (ex: ajout d'un statut "vu"), les sauvegardes centralisées et l'analyse globale des performances via le tableau de bord Admin.

---

### 🚀 Optimisation de la Performance Client : Lazy Loading (Pagination)
Pour garantir que l'application reste fluide sur mobile et web, nous avons implémenté une stratégie de **Chargement Paresseux (Lazy Loading)** :

*   **Problématique**: Charger 2000 messages d'un coup consomme inutilement de la RAM et de la bande passante.
*   **Solution**:
    1.  **Pagination au Curseur**: Nous chargeons les messages par blocs de 20.
    2.  **Détection de Scroll**: Un `ScrollController` détecte quand l'utilisateur atteint le haut de la conversation et déclenche dynamiquement le chargement du bloc suivant.
    3.  **Consommation Réduite**: Le premier affichage est quasi instantané, car seuls les messages visibles sont récupérés initialement.
    4.  **Indicateur de Messages Non Lus**:
        *   **Tracking Backend**: Ajout d'une colonne `est_lu` dans la table `messages` pour suivre l'état de lecture.
        *   **UI Hint**: Utilisation d'une typographie **Grasse (Bold)** dans la sidebar pour signaler visuellement les conversations contenant des messages clients non consultés par l'admin.
        *   **Marquage Automatique**: Les messages sont marqués comme "lus" de manière transparente dès que l'administrateur sélectionne la conversation.
    5.  **Synchronisation Temps Réel Robuste**:
        *   **Politique "Strictly Newer"**: Pour éviter que les flux en temps réel ne remettent par erreur d'anciens messages (ex: au démarrage), nous avons implémenté un verrou de protection. L'interface ne se met à jour que si le message entrant est chronologiquement postérieur au dernier affiché.
        *   **Standardisation Temporelle**: Tous les horodatages sont convertis et comparés en heure locale (`toLocal()`) pour éliminer les bugs de tri liés aux décalages de fuseaux horaires entre le serveur et les clients.
        *   **Ré-ordonnancement Dynamique**: À chaque nouveau message, la liste des conversations (sidebar) est re-triée instantanément pour faire remonter l'interlocuteur actif en haut de la pile.

---

### 🛡️ Sécurité des Données (Isolation)
Bien que les messages soient dans la même table, l'isolation est garantie par les **RLS (Row Level Security)** de Supabase :
*   Chaque requête SQL est filtrée au niveau du serveur.
*   Une entreprise ne peut techniquement jamais "voir" ou "écouter" les messages d'une autre entreprise, même si elle parvenait à modifier le code client.

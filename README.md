# ArgEnPo

Application mobile Flutter de **partage des dépenses en groupe** : créez un
groupe, ajoutez les participants, enregistrez les dépenses et ArgEnPo calcule
automatiquement les remboursements (qui doit quoi à qui, avec le moins
d'échanges possible).

## Fonctionnalités

- Création de groupes avec participants éditables (par e-mail).
- Ajout et modification de dépenses, réparties entre les participants.
- Calcul automatique des remboursements entre membres.
- Comptes par e-mail et mot de passe (Supabase Auth), avec
  confirmation d'inscription et réinitialisation du mot de passe par e-mail
  (envoi via Resend, modèles français dans [`supabase/emails`](supabase/emails)).
- Écran de démarrage animé, interface en français.

## Technique

- **Flutter** (Android, iOS, web, Windows, macOS, Linux).
- **Supabase** (région Paris) : base de données, authentification, politiques
  RLS — schéma SQL dans [`supabase/schema.sql`](supabase/schema.sql).
- Configuration injectée à la compilation : voir
  [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart).

## Démarrage

1. Créer un projet Supabase (région « West EU (Paris) ») et exécuter
   `supabase/schema.sql` dans l'éditeur SQL.
2. Récupérer l'URL du projet et la clé publique (publishable) dans
   *Settings > API*.
3. Configurer Resend comme SMTP personnalisé dans
   *Authentication > Emails > SMTP*, puis coller les modèles français de
   `supabase/emails/` dans *Authentication > Emails > Templates*
   (voir `supabase/emails/README.md`).
4. Lancer l'application :

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=<url> \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=<clé publique>
```

## Structure

```
lib/
  config/      Configuration Supabase (injectée à la compilation)
  constants/   Constantes métier (catégories…)
  models/      Modèles : dépenses, groupes, remboursements, utilisateurs
  screens/     Écrans (démarrage, connexion, groupes, dépenses…)
  services/    Services d'accès aux données (Supabase)
  theme/       Thème centralisé (couleurs, textes, dimensions)
  widgets/     Composants d'interface réutilisables
supabase/
  schema.sql   Schéma de base de données, déclencheurs et politiques RLS
  emails/      Modèles d'e-mails d'authentification en français
```

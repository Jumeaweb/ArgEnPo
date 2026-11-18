# Modèles d'e-mails Supabase en français

Les e-mails d'authentification (envoyés via le SMTP Resend configuré dans le
projet Supabase) sont rédigés par des modèles définis côté Supabase, pas dans
cette application. Ce dossier contient la version française des deux modèles
utilisés par ArgEnPo.

## Où les installer

Dans le dashboard Supabase du projet : **Authentication > Emails > Templates**
puis, pour chacun des deux modèles ci-dessous, ouvrir le modèle, tout
remplacer par le fichier HTML correspondant de ce dossier et enregistrer.

1. **Confirm signup** -> `confirmation-inscription.html`
2. **Reset password** -> `reinitialisation-mot-de-passe.html`

Aucun modèle n'a besoin d'être modifié pour Magic Link ou Invite user :
ArgEnPo n'envoie pas ces e-mails.

## Variables disponibles

- `{{ .ConfirmationURL }}` : lien d'action. Pour la réinitialisation, il pointe
  vers `argenpo://reset-callback`, intercepté par l'application mobile.
- `{{ .Token }}` : code à 6 chiffres, si l'on préfère une saisie manuelle.
- `{{ .Email }}` : adresse du destinataire.

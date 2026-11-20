-- ============================================================
-- ArgEnPo — Alerte e-mail à chaque nouvelle inscription
-- À exécuter dans Supabase → SQL Editor (idempotent : peut être
-- réexécuté sans risque).
--
-- Fonctionnement : un trigger sur auth.users appelle l'API Resend
-- (domaine jumeaweb.fr déjà vérifié) et envoie un e-mail à
-- support@jumeaweb.fr pour chaque nouveau compte créé.
-- La clé Resend est stockée dans le Vault de Supabase (jamais en clair).
-- ============================================================

-- 1. Extensions nécessaires
create extension if not exists pg_net;
create extension if not exists supabase_vault;

-- 2. Clé Resend dans le Vault.
-- ⚠️ REMPLACE 're_REMPLACER_PAR_TA_CLE' par ta clé Resend uniquement
--    DANS LE SQL EDITOR DE SUPABASE (pas dans ce fichier, qui part sur
--    GitHub — la clé doit rester secrète).
--
--    Le script est rejouable : si le secret existe déjà avec une vraie
--    clé, il est laissé tel quel ; s'il est encore au placeholder, il
--    est remplacé. (Pour changer de clé plus tard : delete from
--    vault.secrets where name = 'resend_api_key'; puis create_secret.)
do $$
begin
  if exists (
    select 1 from vault.secrets where name = 'resend_api_key'
  ) then
    if exists (
      select 1 from vault.decrypted_secrets
      where name = 'resend_api_key'
        and decrypted_secret like 're_REMPLACER%'
    ) then
      delete from vault.secrets where name = 'resend_api_key';
      perform vault.create_secret('re_REMPLACER_PAR_TA_CLE', 'resend_api_key');
    else
      raise notice 'Secret resend_api_key déjà présent avec la vraie clé : inchangé.';
    end if;
  else
    perform vault.create_secret('re_REMPLACER_PAR_TA_CLE', 'resend_api_key');
  end if;
end $$;

-- 3. Fonction appelée à chaque inscription
create or replace function public.notify_new_user_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_api_key text;
  v_from    constant text := 'ArgEnPo <contact@jumeaweb.fr>';
  v_to      constant text := 'support@jumeaweb.fr';
  v_email   text;
  v_status  text;
  v_count   int;
  v_when    text;
  v_payload jsonb;
begin
  -- La clé la plus récente du Vault gagne (permet de la remplacer en
  -- créant simplement un nouveau secret du même nom).
  select s.decrypted_secret
    into v_api_key
    from vault.decrypted_secrets s
    where s.name = 'resend_api_key'
    order by s.id desc
    limit 1;

  v_email := coalesce(new.email, '(sans e-mail)');

  -- Pas de clé, pas d'e-mail : on ne bloque jamais l'inscription.
  if v_api_key is null or v_api_key like 're_REMPLACER%' then
    return new;
  end if;

  -- Statut de confirmation au moment de la création du compte.
  v_status := case
                when new.email_confirmed_at is not null then 'e-mail confirmé'
                else 'e-mail PAS ENCORE confirmé'
              end;

  -- Numéro du compte (après lui-même).
  select count(*) + 1 into v_count from auth.users;

  -- ⚠️ created_at peut être null (insertion manuelle : GoTrue le renseigne
  --    lui-même sur une vraie inscription) — et une seule valeur null dans
  --    l'assemblage du html rendrait tout le champ null (erreur 422 Resend).
  --    D'où le coalesce ci-dessous.
  v_when := to_char(coalesce(new.created_at, now()) at time zone 'Europe/Paris',
                    'DD/MM/YYYY à HH24:MI');

  v_payload := jsonb_build_object(
    'from', v_from,
    'to', jsonb_build_array(v_to),
    'reply_to', v_email,
    'subject', '🌱 Nouveau compte ArgEnPo — ' || v_email,
    'html',
      '<div style="font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">'
      || '<div style="background:#1B5E20;color:#ffffff;padding:20px 24px;text-align:center">'
      || '<div style="font-size:20px;font-weight:bold">🌱 ArgEnPo</div>'
      || '<div style="font-size:12px;color:#c8e6c9">Argent Entre Potes — nouvelle inscription</div>'
      || '</div>'
      || '<div style="padding:24px;color:#212121">'
      || '<p style="font-size:15px;margin:0 0 12px">Un nouveau compte vient d''être créé :</p>'
      || '<p style="font-size:17px;font-weight:bold;margin:0 0 4px">' || v_email || '</p>'
      || '<p style="font-size:13px;color:#757575;margin:0">' || v_status || '</p>'
      || '<p style="font-size:13px;color:#757575;margin:16px 0 0">'
      || 'Compte n° ' || v_count || ' — créé le ' || v_when || '</p>'
      || '</div>'
      || '<div style="background:#F1FAF3;color:#757575;padding:12px 24px;font-size:11px;text-align:center">'
      || 'Notification automatique de Supabase — ArgEnPo</div>'
      || '</div>'
  );

  -- Fire-and-forget : l'inscription ne doit jamais attendre l'e-mail.
  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
                 'Authorization', 'Bearer ' || v_api_key,
                 'Content-Type', 'application/json'
               ),
    body    := v_payload
  );

  return new;
end $$;

-- 4. Le trigger sur la table des comptes
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.notify_new_user_signup();

-- 5. (Facultatif) Test immédiat sans créer un vrai compte :
--    créer puis supprimer un utilisateur fictif déclenche l'e-mail.
--    Décommenter puis exécuter (« id » et « created_at » sont obligatoires,
--    sans valeur par défaut dans auth.users) :
-- insert into auth.users (id, email, email_confirmed_at, encrypted_password, created_at)
-- values (gen_random_uuid(), 'test-notif@exemple.fr', now(), '', now());
-- delete from auth.users where email = 'test-notif@exemple.fr';

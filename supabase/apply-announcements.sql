-- ============================================================
-- ArgEnPo - Journal des annonces de version envoyées par e-mail
-- À exécuter une fois dans l'éditeur SQL du dashboard Supabase.
-- (Idempotent : peut être ré-exécuté sans erreur.)
-- ============================================================

create table if not exists public.email_announcements (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  recipients_count int not null,
  failed_count int not null default 0,
  sent_by uuid,
  sent_at timestamptz not null default now()
);

alter table public.email_announcements enable row level security;

-- Aucune policy : la table n'est accessible qu'avec la clé
-- service_role (page /admin). Les clients ne lisent ni n'écrivent.

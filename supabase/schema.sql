-- ============================================================
-- ArgEnPo - Schéma Supabase (Postgres)
-- À exécuter dans l'éditeur SQL du dashboard Supabase.
-- ============================================================

-- ---------- Table des profils utilisateurs ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  created_at timestamptz not null default now()
);

-- ---------- Table des groupes ----------
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  members uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

-- ---------- Table des dépenses ----------
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  title text not null,
  amount numeric(12, 2) not null,
  paid_by uuid not null references public.profiles(id),
  participants uuid[] not null default '{}',
  category text not null default 'Autre',
  created_at timestamptz not null default now()
);

-- ---------- Table des remboursements ----------
create table if not exists public.repayments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  from_user uuid not null references public.profiles(id),
  to_user uuid not null references public.profiles(id),
  amount numeric(12, 2) not null,
  created_at timestamptz not null default now()
);

-- ---------- Création automatique du profil à l'inscription ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'name', '')
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = excluded.display_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------- Fonction d'appartenance à un groupe ----------
-- security definer : évite la récursivité des règles RLS.
create or replace function public.is_group_member(group_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.groups g
    where g.id = group_id
      and auth.uid() = any (g.members)
  );
$$;

-- ============================================================
-- Sécurité (Row Level Security)
-- ============================================================

-- ---------- profiles ----------
alter table public.profiles enable row level security;

drop policy if exists "Lire les profils des groupes communs" on public.profiles;
create policy "Lire les profils des groupes communs"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from public.groups g
      where auth.uid() = any (g.members)
        and profiles.id = any (g.members)
    )
  );

drop policy if exists "Créer son propre profil" on public.profiles;
create policy "Créer son propre profil"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Mettre à jour son propre profil" on public.profiles;
create policy "Mettre à jour son propre profil"
  on public.profiles for update
  using (auth.uid() = id);

-- ---------- groups ----------
alter table public.groups enable row level security;

drop policy if exists "Voir ses groupes" on public.groups;
create policy "Voir ses groupes"
  on public.groups for select
  using (auth.uid() = any (members));

drop policy if exists "Créer un groupe" on public.groups;
create policy "Créer un groupe"
  on public.groups for insert
  with check (created_by = auth.uid());

drop policy if exists "Modifier ses groupes" on public.groups;
create policy "Modifier ses groupes"
  on public.groups for update
  using (auth.uid() = any (members));

drop policy if exists "Supprimer son groupe" on public.groups;
create policy "Supprimer son groupe"
  on public.groups for delete
  using (auth.uid() = created_by);

-- ---------- expenses ----------
alter table public.expenses enable row level security;

drop policy if exists "Voir les dépenses de ses groupes" on public.expenses;
create policy "Voir les dépenses de ses groupes"
  on public.expenses for select
  using (public.is_group_member(group_id));

drop policy if exists "Ajouter une dépense à ses groupes" on public.expenses;
create policy "Ajouter une dépense à ses groupes"
  on public.expenses for insert
  with check (public.is_group_member(group_id));

drop policy if exists "Modifier les dépenses de ses groupes" on public.expenses;
create policy "Modifier les dépenses de ses groupes"
  on public.expenses for update
  using (public.is_group_member(group_id));

drop policy if exists "Supprimer les dépenses de ses groupes" on public.expenses;
create policy "Supprimer les dépenses de ses groupes"
  on public.expenses for delete
  using (public.is_group_member(group_id));

-- ---------- repayments ----------
alter table public.repayments enable row level security;

drop policy if exists "Voir les remboursements de ses groupes" on public.repayments;
create policy "Voir les remboursements de ses groupes"
  on public.repayments for select
  using (public.is_group_member(group_id));

drop policy if exists "Enregistrer un remboursement dans ses groupes" on public.repayments;
create policy "Enregistrer un remboursement dans ses groupes"
  on public.repayments for insert
  with check (public.is_group_member(group_id));

drop policy if exists "Supprimer les remboursements de ses groupes" on public.repayments;
create policy "Supprimer les remboursements de ses groupes"
  on public.repayments for delete
  using (public.is_group_member(group_id));

-- ---------- Recherche de membre par email (exécutée par l'app) ----------
create or replace function public.find_profile_id_by_email(search_email text)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from public.profiles
  where lower(email) = lower(search_email)
  limit 1;
$$;

revoke execute on function public.find_profile_id_by_email(text) from anon, public;
grant execute on function public.find_profile_id_by_email(text) to authenticated;

-- ---------- Statistiques d'installation (anonymes) ----------
-- Chaque installation de l'application s'identifie par un identifiant
-- aléatoire (uuid) stocké sur le téléphone : aucune donnée personnelle.
create table if not exists public.app_installs (
  install_id uuid primary key,
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  app_version text,
  platform text
);

-- Ping de démarrage : à chaque lancement, l'app met à jour last_seen.
create or replace function public.ping_app_install(
  ping_install_id uuid,
  ping_app_version text,
  ping_platform text
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.app_installs (install_id, app_version, platform)
  values (ping_install_id, ping_app_version, ping_platform)
  on conflict (install_id) do update
    set last_seen = now(),
        app_version = excluded.app_version,
        platform = excluded.platform;
$$;

-- Agrégats publics uniquement (exécutée par la page Jumeaweb).
create or replace function public.app_usage_stats()
returns table (total_installs bigint, active_30d bigint, active_7d bigint)
language sql
security definer
stable
set search_path = public
as $$
  select
    count(*) as total_installs,
    count(*) filter (where last_seen > now() - interval '30 days') as active_30d,
    count(*) filter (where last_seen > now() - interval '7 days') as active_7d
  from public.app_installs;
$$;

grant execute on function public.ping_app_install(uuid, text, text) to anon, authenticated;
grant execute on function public.app_usage_stats() to anon, authenticated;

-- ============================================================
-- Invitations de groupe
-- Un membre invite une personne par son email exact. La
-- personne désignée voit l'invitation dans l'application et
-- peut l'accepter ou la refuser.
-- Section idempotente (peut être réexécutée sans erreur).
-- ============================================================

-- ---------- Table des invitations ----------
create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  email text not null,
  group_name text not null default '',
  invited_user_id uuid references public.profiles(id),
  invited_by uuid not null references public.profiles(id),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);

create index if not exists invitations_invited_user_idx
  on public.invitations (invited_user_id)
  where status = 'pending';
create index if not exists invitations_email_idx
  on public.invitations (lower(email))
  where status = 'pending';
create index if not exists invitations_group_idx
  on public.invitations (group_id, status);

alter table public.invitations enable row level security;

drop policy if exists "Lire les invitations qui me concernent" on public.invitations;
create policy "Lire les invitations qui me concernent"
  on public.invitations for select
  using (
    auth.uid() = invited_user_id
    or auth.uid() = invited_by
    or public.is_group_member(group_id)
  );

drop policy if exists "Inviter un ami dans mes groupes" on public.invitations;
create policy "Inviter un ami dans mes groupes"
  on public.invitations for insert
  with check (
    auth.uid() = invited_by
    and public.is_group_member(group_id)
  );

drop policy if exists "Repondre a ses invitations" on public.invitations;
create policy "Repondre a ses invitations"
  on public.invitations for update
  using (auth.uid() = invited_user_id);

drop policy if exists "Annuler une invitation de son groupe" on public.invitations;
create policy "Annuler une invitation de son groupe"
  on public.invitations for delete
  using (
    auth.uid() = invited_by
    or public.is_group_member(group_id)
  );

-- ---------- Association des invitations et des nouveaux inscrits ----------
-- Quand la personne invitee cree son compte apres l'invitation,
-- on rattache les invitations en attente a son profil.
create or replace function public.link_pending_invitations()
returns void
language sql
security definer
set search_path = public
as $$
  update public.invitations
  set invited_user_id = auth.uid()
  where lower(email) = lower(coalesce(auth.email(), ''))
    and invited_user_id is null
    and status = 'pending';
$$;

grant execute on function public.link_pending_invitations() to authenticated;

-- ---------- Acceptation d'une invitation ----------
-- security definer : la personne invitee n'est pas encore membre du
-- groupe, elle ne peut donc pas modifier la liste des membres.
create or replace function public.accept_invitation(p_invitation_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_email text := lower(coalesce(auth.email(), ''));
  v_group_id uuid;
  v_invited_user uuid;
  v_status text;
  v_inv_email text;
  v_members uuid[];
begin
  select group_id, invited_user_id, status, lower(email)
    into v_group_id, v_invited_user, v_status, v_inv_email
  from public.invitations
  where id = p_invitation_id;

  if not found then
    raise exception 'Invitation introuvable';
  end if;

  if v_status <> 'pending' then
    raise exception 'Cette invitation n''est plus disponible';
  end if;

  if v_invited_user is null or v_invited_user <> v_user then
    -- L'invitation n'etait pas rattachee a ce compte : on la rattache
    -- si l'email correspond, sinon on refuse.
    if v_inv_email <> v_email then
      raise exception 'Cet email ne correspond pas a l''invitation';
    end if;

    update public.invitations
    set invited_user_id = v_user
    where id = p_invitation_id;
  end if;

  select members into v_members from public.groups where id = v_group_id;

  if not found then
    raise exception 'Groupe introuvable';
  end if;

  if not (v_user = any (v_members)) then
    update public.groups
    set members = array_append(members, v_user)
    where id = v_group_id;
  end if;

  update public.invitations
  set status = 'accepted',
      accepted_at = now(),
      invited_user_id = v_user
  where id = p_invitation_id;

  return v_group_id;
end;
$$;

grant execute on function public.accept_invitation(uuid) to authenticated;

-- ============================================================
-- Notifications in-app
-- Générées automatiquement côté serveur (triggers) :
-- dépense ajoutée, remboursement enregistré, réponse à une
-- invitation. Les clients ne font que lire / marquer comme lues /
-- supprimer les leurs.
-- Section idempotente (peut être réexécutée sans erreur).
-- ============================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  message text not null,
  group_id uuid references public.groups(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);
create index if not exists notifications_unread_idx
  on public.notifications (user_id)
  where is_read = false;

alter table public.notifications enable row level security;

drop policy if exists "Lire ses notifications" on public.notifications;
create policy "Lire ses notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "Marquer ses notifications comme lues" on public.notifications;
create policy "Marquer ses notifications comme lues"
  on public.notifications for update
  using (auth.uid() = user_id);

drop policy if exists "Supprimer ses notifications" on public.notifications;
create policy "Supprimer ses notifications"
  on public.notifications for delete
  using (auth.uid() = user_id);

-- ---------- Fonctions utilitaires des triggers ----------

create or replace function public._profile_label(p_id uuid)
returns text
language sql
stable
set search_path = public
as $$
  select coalesce(nullif(display_name, ''), email, 'Un membre')
  from public.profiles
  where id = p_id;
$$;

-- Dépense ajoutée : prévenir tous les membres sauf le payeur.
create or replace function public.notify_expense_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := coalesce(auth.uid(), new.paid_by);
  v_actor_name text;
  v_group_name text;
  m uuid;
begin
  v_actor_name := public._profile_label(new.paid_by);

  select name into v_group_name from public.groups where id = new.group_id;
  v_group_name := coalesce(v_group_name, 'un groupe');

  for m in
    select unnest(members) from public.groups where id = new.group_id
  loop
    if m <> v_actor then
      insert into public.notifications (user_id, type, title, message, group_id)
      values (
        m,
        'expense',
        'Nouvelle dépense',
        v_actor_name || ' a ajouté « ' || new.title || ' » ('
          || trim(trailing '0' from trim(trailing '.' from to_char(new.amount, 'FM999999990.00')))
          || ' €) dans ' || v_group_name || '.',
        new.group_id
      );
    end if;
  end loop;

  return new;
end;
$$;

drop trigger if exists on_expense_created on public.expenses;
create trigger on_expense_created
after insert on public.expenses
for each row execute function public.notify_expense_created();

-- Remboursement enregistré : prévenir concernés sauf l'auteur.
create or replace function public.notify_repayment_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := coalesce(auth.uid(), new.from_user);
  v_actor_name text;
  v_group_name text;
  r record;
begin
  v_actor_name := public._profile_label(v_actor);

  select name into v_group_name from public.groups where id = new.group_id;
  v_group_name := coalesce(v_group_name, 'un groupe');

  for r in
    select distinct u as uid from unnest(array[new.from_user, new.to_user]) as u
    where u <> v_actor
  loop
    insert into public.notifications (user_id, type, title, message, group_id)
    values (
      r.uid,
      'repayment',
      'Nouveau remboursement',
      v_actor_name || ' a enregistré un remboursement de '
        || trim(trailing '0' from trim(trailing '.' from to_char(new.amount, 'FM999999990.00')))
        || ' € dans ' || v_group_name || '.',
      new.group_id
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists on_repayment_created on public.repayments;
create trigger on_repayment_created
after insert on public.repayments
for each row execute function public.notify_repayment_created();

-- Réponse à une invitation : prévenir l'invitant.
create or replace function public.notify_invitation_answered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_user text;
  v_group_name text;
begin
  if new.status = old.status then
    return new;
  end if;

  -- L'invitant n'a pas besoin d'être prévenu de sa propre action.
  if v_actor = new.invited_by then
    return new;
  end if;

  v_user := coalesce(
    public._profile_label(new.invited_user_id),
    new.email,
    'Un utilisateur'
  );

  select name into v_group_name from public.groups where id = new.group_id;
  v_group_name := coalesce(v_group_name, 'un groupe');

  if new.status = 'accepted' then
    insert into public.notifications (user_id, type, title, message, group_id)
    values (
      new.invited_by,
      'invitation',
      'Invitation acceptée',
      v_user || ' a rejoint le groupe ' || v_group_name || '.',
      new.group_id
    );
  elsif new.status = 'declined' then
    insert into public.notifications (user_id, type, title, message, group_id)
    values (
      new.invited_by,
      'invitation',
      'Invitation refusée',
      v_user || ' n''a pas rejoint le groupe ' || v_group_name || '.',
      new.group_id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_invitation_answered on public.invitations;
create trigger on_invitation_answered
after update on public.invitations
for each row execute function public.notify_invitation_answered();

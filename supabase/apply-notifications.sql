-- ============================================================
-- ArgEnPo - Notifications in-app (à exécuter une fois dans
-- l'éditeur SQL du dashboard Supabase ; qu'après apply-invitations.sql).
-- ============================================================

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

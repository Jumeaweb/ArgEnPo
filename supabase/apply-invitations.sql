-- ============================================================
-- ArgEnPo - Invitations de groupe (à exécuter une fois dans
-- l'éditeur SQL du dashboard Supabase ; section idempotente).
-- ============================================================

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

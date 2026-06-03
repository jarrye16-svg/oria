-- Oria v21.2 - protecao contra cartoes duplicados
-- Opcional. Rode depois de limpar os cartões duplicados.
-- Mantem o banco atual, mas o app passa a tratar financial_cards.name como bandeira/cartao.

create unique index if not exists financial_cards_unique_house_brand_owner
on public.financial_cards (
  house_id,
  lower(trim(name)),
  lower(trim(coalesce(owner_name, '')))
);

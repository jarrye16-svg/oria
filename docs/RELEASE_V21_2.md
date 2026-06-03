# Oria v21.2 - cartões: bandeira e limpeza

Ajustes:
- Campo "Nome de exibição" virou "Bandeira do cartão".
- Textos de cartões corrigidos.
- Exclusão de cartão mantida.
- Migration opcional 0016_card_brand_unique_guard.sql para impedir duplicados por casa/bandeira/dono.
- Não muda nome de coluna no banco para não quebrar os dados existentes.

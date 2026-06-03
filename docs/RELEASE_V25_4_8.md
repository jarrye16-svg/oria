# Oria v25.4.8 - correção remover membros

Correções:
- Corrigido erro ao remover membro da casa.
- A função antiga tentava usar status "removed", mas a tabela só aceita active, invited e blocked.
- Agora remover membro usa status "blocked".
- Lista de membros mostra apenas membros ativos.
- Erros de permissão agora aparecem com motivo real na tela.
- Requer rodar a migration 0017_fix_remove_members.sql no Supabase.

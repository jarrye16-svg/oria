# Checklist de seguranca para dados pessoais no Oria

## Decisao atual

Cadastro de novos usuarios continua permitido. Isso e aceitavel para teste real, desde que o Supabase esteja com RLS correto.

## Fazer agora no Supabase

1. Authentication > URL Configuration
   - Site URL:
     https://jarrye16-svg.github.io/oria/
   - Redirect URLs:
     https://jarrye16-svg.github.io/oria/

2. SQL Editor
   - Rodar as migrations em ordem:
     0001_init_oria.sql
     0002_cards_goals_mobile_first.sql
     0003_professional_cleanup.sql
     0004_security_hardening.sql
     0005_personal_security_review.sql
     0006_performance_cleanup.sql

3. Database > Security Advisor
   - Rodar e revisar alertas.

4. Project Settings > API
   - Nunca copiar SERVICE_ROLE para GitHub, app, navegador ou ChatGPT.
   - A publishable/anon key pode ficar no front-end porque RLS protege os dados.

## O que esta versao v13.1 mantem

- Criar acesso continua aparecendo no login.
- RLS continua reforcado.
- Funcao antiga de demo fica removida pela migration 0005.
- Indices adicionais melhoram consultas por mes, cartao, status e meta.

## Ainda falta depois

- Convite de membros por e-mail.
- Backup/exportacao.
- Auditoria visual de quem editou/excluiu.
- Melhor controle de permissoes por casa.

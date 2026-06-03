# Seguranca do Oria

## O que foi aplicado nesta versao

- Migration `0004_security_hardening.sql`.
- RLS habilitado nas tabelas usadas pelo app.
- Acesso anonimo removido das tabelas publicas.
- Grants minimos para `authenticated`.
- RPCs principais liberadas apenas para usuarios autenticados.
- Indices de suporte para RLS/filtros.
- Constraints para evitar valores invalidos/absurdos.
- `.gitignore` reforcado para evitar subir segredos.
- GitHub Actions preparado com GitHub Secrets.
- CSP basica no `web/index.html`.
- Scripts de build e checagem de possiveis segredos.

## Regra de ouro

Nunca colocar no app/web/GitHub:

- `service_role`
- `sb_secret`
- senha do banco
- JWT secret
- chaves privadas

A chave publishable/anon pode aparecer no navegador, mas somente e segura se RLS estiver correto.

## Antes de publicar

1. Rode as migrations:
   - `0001_init_oria.sql`
   - `0002_cards_goals_mobile_first.sql`
   - `0003_professional_cleanup.sql`
   - `0004_security_hardening.sql`

2. No Supabase:
   - Authentication > URL Configuration:
     - Site URL: URL final do app
     - Redirect URLs: URL final do app
   - Database > Security Advisor:
     - rodar e corrigir alertas
   - Database > Performance Advisor:
     - rodar e revisar alertas

3. No GitHub:
   - criar os secrets:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`

4. Rodar local:
   ```powershell
   .\tool\security_check.ps1
   .\tool\build_web_release.ps1
   ```

## Observacoes

- GitHub Pages nao permite headers HTTP customizados avancados. Por isso o projeto usa CSP via meta tag.
- Para maxima seguranca em producao, Cloudflare Pages/Netlify/Vercel permitem configurar headers melhores.
- Nao existe app 100% "a prova de hacker"; o objetivo e reduzir superficie de ataque e garantir que vazamento da chave publica nao entregue dados.

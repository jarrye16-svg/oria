# Seguranca do Oria

## O que foi aplicado nesta versao

- As migrations anteriores mantem RLS nas tabelas financeiras e na lista de RPCs.
- `0024_security_join_attempt_limits.sql` restringe execute a uma allowlist, oculta a tabela de convites e guarda o bloqueio em schema privado com RLS.
- Codigos de familia novos tem 8 digitos aleatorios. Cada conta tem 5 erros em 15 minutos; a partir do quinto, espera 15 minutos. Codigos antigos de 6 digitos continuam validos ate expirarem.
- `0025_legacy_join_code_compatibility.sql` mantem clientes/PWAs antigos funcionais e faz suas tentativas passarem pelo mesmo bloqueio.
- O app aceita codigos de 6 ou 8 digitos e informa o bloqueio sem revelar se uma familia/codigo especifico existe.
- Cadastro e redefinicao exigem senha de pelo menos 12 caracteres.
- Na configuracao Auth do Supabase, a troca segura de senha foi habilitada; o endpoint de tokens foi reduzido de 150 para 30 requisicoes por 5 minutos por IP, e cadastro/entrada permanece em 10 por 5 minutos por IP.
- CSP basica no `web/index.html`; `.gitignore`, workflows e scripts tambem foram revisados.

## Regra de ouro

Nunca colocar no app/web/GitHub:

- `service_role`
- `sb_secret`
- senha do banco
- JWT secret
- chaves privadas

A chave publishable/anon pode aparecer no navegador, mas somente e segura se RLS estiver correto.

## Antes de publicar

1. Rode as migrations em ordem, incluindo `0024` e `0025`.

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
- CSP via meta tag nao consegue aplicar `frame-ancestors`; para protecao contra incorporacao, o host deve enviar `Content-Security-Policy`/`X-Frame-Options` como cabecalho HTTP.
- O bloqueio do codigo de familia e por conta; chamadas Auth tambem estao limitadas por IP. Uma camada adicional por IP no RPC de convites exigiria passar esse fluxo por uma Edge Function com rate limiter centralizado.
- O projeto esta no plano Free: a deteccao de senhas vazadas do Supabase nao pode ser ativada sem upgrade. A confirmacao de e-mail permanece desligada, pois exige configurar e validar o envio de e-mails antes de nao bloquear novos cadastros.
- O fluxo legado de entrada por codigo retorna erro generico para tentativas invalidas ate o frontend novo ser publicado; a contagem e o bloqueio continuam sendo aplicados no banco.
- Para maxima seguranca em producao, Cloudflare Pages/Netlify/Vercel permitem configurar headers melhores.
- Nao existe app 100% "a prova de hacker"; o objetivo e reduzir superficie de ataque e garantir que vazamento da chave publica nao entregue dados.

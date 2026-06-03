# Supabase Setup

1. Abra o SQL Editor do Supabase.
2. Rode as migrations em ordem:

```txt
0001_init_oria.sql
0002_cards_goals_mobile_first.sql
0003_professional_cleanup.sql
```

3. Em Authentication > Providers > Email:
   - para desenvolvimento, pode deixar confirmacao de e-mail desligada.
   - para producao, ative confirmacao de e-mail.

4. Use a URL e publishable/anon key no `launch.json` ou ao rodar com `--dart-define`.

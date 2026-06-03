# Oria v19 - convite com confirmacao de ingresso

Fluxo novo:
- Admin informa o e-mail do membro e gera link.
- Pessoa abre o link.
- Se nao estiver logada, cai em login/cadastro com contexto de convite.
- Depois do login/cadastro, aparece tela perguntando se quer ingressar no grupo.
- Se o e-mail logado for diferente do e-mail convidado, o app bloqueia e orienta sair/entrar com o e-mail certo.
- So apos confirmar "Ingressar no grupo" o vinculo e criado.
- Migration 0015_invite_join_confirm.sql.

# Oria v16 - membros e convites

Implementado:
- Tela Ajustes > Membros e convites.
- Criar convite por e-mail/link.
- Copiar link de convite.
- Listar membros da casa.
- Listar e cancelar convites pendentes.
- Aceitar convite via link: /oria/?invite=TOKEN.
- Ao aceitar, o usuario entra como membro da mesma casa e ve tudo que o admin ve.
- Migration 0009_member_invites.sql.

Observacao:
- O app nao cria senha para outra pessoa diretamente no navegador por seguranca.
- O fluxo seguro e: gerar convite, pessoa cria acesso com o proprio e-mail/senha e o convite vincula a casa.

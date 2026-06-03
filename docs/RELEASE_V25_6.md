# Oria v25.6 - entrada por codigo da familia

Ajustes:
- Novo fluxo de entrada por codigo temporario.
- Admin gera codigo de 6 digitos na tela Membros.
- Codigo vale 15 minutos.
- Pessoa cria/entra no Oria e informa:
  - nome da familia
  - codigo de 6 digitos
- Nao depende de link preso ao e-mail.
- Convite por link/e-mail continua existindo, mas ficou como opcional/avancado.
- Onboarding agora permite "Entrar em uma familia" ou "Criar uma nova casa".

Migration:
- 0018_family_join_codes.sql

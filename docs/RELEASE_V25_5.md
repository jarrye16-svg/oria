# Oria v25.5 - redefinir senha por e-mail

Ajustes:
- "Esqueci minha senha" agora envia link com redirect correto para o Oria.
- Adicionada tela "Criar nova senha".
- O link de recuperação volta para o app com ?reset=1.
- A nova tela chama updateUser para salvar a nova senha.
- Mensagem de sucesso orienta conferir spam/lixo eletrônico.
- Sem migration nova.

Configuração necessária no Supabase:
- Authentication > URL Configuration
- Site URL: https://jarrye16-svg.github.io/oria/
- Redirect URLs: https://jarrye16-svg.github.io/oria/**

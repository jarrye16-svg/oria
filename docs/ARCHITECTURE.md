# Arquitetura

## Estrutura principal

```txt
lib/
  app/          Tema e app root
  core/         Formatadores, status, configuracoes
  models/       Modelos de dominio
  screens/      Telas do app
  services/     Acesso ao Supabase
  widgets/      Componentes reutilizaveis
```

## Regras

- UI nao conversa diretamente com Supabase.
- Telas usam services.
- Services retornam models.
- Componentes visuais reutilizaveis ficam em `widgets`.
- Linguagem do app deve ser simples e direta.
- Evitar campos desnecessarios no fluxo de lancamento.

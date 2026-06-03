# Publicar Oria como site/PWA pelo GitHub Pages

## 1. Criar repositorio no GitHub

Exemplo:

```txt
oria
```

## 2. Subir o projeto

Na pasta do projeto:

```powershell
git init
git branch -M main
git add .
git commit -m "primeira versao segura do Oria"
git remote add origin https://github.com/SEU_USUARIO/oria.git
git push -u origin main
```

## 3. Criar Secrets

No GitHub:

```txt
Settings > Secrets and variables > Actions > New repository secret
```

Crie:

```txt
SUPABASE_URL
SUPABASE_ANON_KEY
```

Valores:

```txt
SUPABASE_URL=https://hrfsphtwslcjnpvcwdxl.supabase.co
SUPABASE_ANON_KEY=sb_publishable__C7YM-EoJQgqdduVFb0WTQ_53AXMEgp
```

## 4. Ativar GitHub Pages

```txt
Settings > Pages > Source: GitHub Actions
```

## 5. Publicar

Basta dar push na branch `main`.

O workflow `.github/workflows/deploy-web.yml` vai gerar o site em release e publicar.

## 6. Instalar como app no iPhone

No Safari:

```txt
Abrir URL do GitHub Pages
Compartilhar
Adicionar a Tela de Inicio
```

## 7. Instalar como app no Android

No Chrome:

```txt
Abrir URL
Menu
Adicionar a tela inicial
```

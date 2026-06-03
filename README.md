# Oria

App web/PWA para controle financeiro familiar.

## Rodar local

```powershell
flutter clean
flutter pub get
flutter analyze
.\tool\run_web_local_secure.ps1
```

## Publicar

```powershell
git add .
git commit -m "Atualiza Oria"
git push
```

O GitHub Actions publica em:

```txt
https://jarrye16-svg.github.io/oria/
```

## Supabase

Rodar migrations em ordem:

```txt
0001_init_oria.sql
0002_cards_goals_mobile_first.sql
0003_professional_cleanup.sql
0004_security_hardening.sql
0005_personal_security_review.sql
0006_performance_cleanup.sql
0007_features_settings.sql
0008_review_optimize.sql
0009_member_invites.sql
0010_professional_core.sql
0011_invite_diagnostics.sql
0012_fix_invite_email_ambiguous.sql
0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql
```

## Prioridade atual

1. Manter dados seguros.
2. Garantir backup/exportacao.
3. Estabilizar lancamentos, cartoes e relatorios.
4. Depois evoluir membros/convites.
5. Por ultimo estudar passkey/biometria.


## v16_member_invites

- Membros e convites por link/e-mail.
- Aceite automatico via `?invite=TOKEN` depois do login/cadastro.
- Rodar `0009_member_invites.sql
0010_professional_core.sql
0011_invite_diagnostics.sql
0012_fix_invite_email_ambiguous.sql
0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql`.




## v17_1_convite_link_sem_email

- Envio de e-mail removido por enquanto.
- Convites continuam por link copiado.
- Nao precisa configurar SMTP nem Supabase Edge Function.


## v18_professional_core

- Detalhamento de faturas de cartao.
- Importacao CSV.
- Controle de membros: alterar perfil e remover acesso.
- Rodar `0010_professional_core.sql
0011_invite_diagnostics.sql
0012_fix_invite_email_ambiguous.sql
0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql`.


## v18_2_invite_diagnostics

- Erro detalhado na criacao de convites.
- Rodar `0011_invite_diagnostics.sql
0012_fix_invite_email_ambiguous.sql
0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql` se convites continuarem falhando.


## v18_3_fix_invite_email_ambiguous

- Corrige erro `column reference "email" is ambiguous` na criacao de convite.
- Rodar `0012_fix_invite_email_ambiguous.sql
0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql`.


## v18_4_clipboard_safe

- Convite nao falha mais quando o navegador bloqueia copiar automaticamente.
- Link continua aparecendo na tela para copiar manualmente.


## v18_5_invite_flow_fix

- Convite por link sem clipboard automatico.
- Convidado com erro de convite nao cai mais no criar casa.
- Rodar `0013_invite_flow_fix.sql
0014_admin_guard.sql
0015_invite_join_confirm.sql`.


## v18_6_admin_guard

- Protecao para nunca deixar a casa sem administrador.
- O admin nao consegue rebaixar/remover ele mesmo pelo app.
- Rodar `0014_admin_guard.sql
0015_invite_join_confirm.sql`.


## v19_invite_join_confirm

- Convite por link com confirmacao de ingresso no grupo.
- Rodar `0015_invite_join_confirm.sql`.


## v20_ui_cleanup

- Limpeza de textos e informacoes tecnicas da interface.
- Cards de Cartoes e Porquinhos mais compactos.


## v20_1_compact_cards

- Reduz tamanho visual dos cartoes e deixa a tela de Cartoes mais enxuta.


## v20_2_goals_fix

- Corrige layout da tela Metas/Porquinhos em telas menores.


## v20_3_goals_layout_clean

- Simplifica o rodape do card de metas para evitar glitches visuais no iPhone.


## v21_mobile_polish

- Polimento geral mobile.
- Cards e headers mais compactos.
- Textos menos tecnicos.
- Sem migration nova.


## v21_1_cards_fix_delete

- Corrige layout de cartoes.
- Adiciona exclusao de cartao.
- Sem migration nova.


## v21_2_card_brand_cleanup

- Campo do cartão renomeado na interface para Bandeira do cartão.
- Mantém compatibilidade com a tabela atual.
- Inclui trava opcional contra cartão duplicado por casa/bandeira/dono.


## v21_3_cards_header_fix

- Corrige header da tela Cartões em telas estreitas.


## v21_4_public_share

- Link publico em Ajustes para indicar o Oria sem vincular a pessoa a familia atual.
- Sem migration nova.


## v21_5_monthly_reports

- Nova tela de Controle mensal com grafico, resumo e quebras por categoria/cartao/status.
- Sem migration nova.


## v21_5_1_reports_build_fix

- Corrige build da tela Controle mensal.
- Sem migration nova.


## v21_5_2_build_fix

- Corrige erros do flutter analyze da v21.5.1.
- Sem migration nova.


## v21_5_3_member_service_fix

- Corrige arquivo de membros/convites corrompido.
- Sem migration nova.


## v22_card_invoices

- Fatura por cartão com status, progresso e marcação de pagamento.
- Sem migration nova.


## v22_1_cards_analyze_fix

- Corrige flutter analyze da v22.
- Sem migration nova.


## v22_2_invoice_button_fix

- Corrige analyze do botão Ver fatura.
- Sem migration nova.


## v23_monthly_history

- Controle mensal com historico real dos ultimos 6 meses.
- Sem migration nova.


## v24_smart_import

- Importação de CSV com validação, resumo e proteção contra duplicados.
- Sem migration nova.


## v25_excel_import

- Importação direta de Excel/CSV com leitura inteligente.
- Sem migration nova.


## v25_1_easy_import

- Simplifica a tela de importação para usuários leigos.
- Sem migration nova.


## v25_2_import_db_compat

- Corrige salvamento de importação quando havia categorias como Moto/Financiamento ou Terceiros.
- Sem migration nova.


## v25_3_legacy_ods_import

- Suporte a ODS e ao formato antigo "Casa 2026".
- Sem migration nova.


## v25_4_delete_goals

- Permite apagar metas/porquinhos criados.
- Sem migration nova.


## v25_4_1_dependency_fix

- Corrige conflito de dependência archive/spreadsheet_decoder.
- Sem migration nova.


## v25_4_2_visible_delete_goal

- Mostra botão de apagar porquinho diretamente no card.
- Sem migration nova.

## v25_4_3_dashboard_cards_fix

- Corrige corte/estouro visual nos cards-resumo da tela inicial.
- Melhora leitura no iPhone e outras telas menores.
- Sem migration nova.

## v25_4_4_clean_home_cards

- Remove subtítulos dos cards-resumo da home e aumenta os valores sem aumentar os cards.
- Sem migration nova.

## v25_4_5_home_cards_balance

- Home com cards mais equilibrados: valores grandes, subtítulos curtos e menos espaço vazio.
- Sem migration nova.


## v25_4_6_remove_import_backup

- Remove Importar planilha e Backup/exportação dos ajustes.
- Sem migration nova.


## v25_4_7_quick_entry_actions

- Adiciona ações rápidas nos lançamentos: editar, marcar pago/pendente, copiar para o próximo mês e apagar.
- Sem migration nova.


## v25_4_8_fix_remove_members

- Corrige remoção de membros da casa.
- Requer rodar a migration 0017_fix_remove_members.sql no Supabase.


## v25_4_9_invite_login_ux

- Melhora o fluxo de convite quando o e-mail convidado já tem cadastro.
- Sem migration nova.


## v25_5_password_reset

- Implementa fluxo de redefinição de senha por e-mail.
- Requer configurar Site URL e Redirect URLs no Supabase.
- Sem migration nova.


## v25_6_family_code_invite

- Adiciona entrada por codigo temporario da familia.
- Requer rodar a migration 0018_family_join_codes.sql.


## v25_6_1_direct_family_link

- Adiciona link direto temporário da família, válido por 15 minutos e uso único.
- Requer rodar a migration 0019_direct_family_join_link.sql.

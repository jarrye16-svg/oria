# Oria v25.3 - importação legado Casa 2026 / ODS

Ajustes:
- Importação aceita .ods além de .xlsx/.xls/.csv.
- Leitor ODS interno para planilhas antigas do LibreOffice/Excel.
- Detecta automaticamente planilha no formato "CONTAS DA NOSSA CASA".
- Importa apenas a aba correspondente ao mês atual selecionado no app.
- Interpreta blocos da planilha antiga:
  - DESPESAS FIXAS CASA -> Casa
  - PLATAFORMAS ASSINADAS -> Plataformas
  - SALÁRIO -> Entradas
  - DESPESAS CARTÕES DE CRÉDITO -> Cartões de crédito
  - FINANCIAMENTO MOTO -> Moto/Financiamento
  - PAGAR PARA TERCEIROS -> Terceiros
- Ignora SOMA TOTAL, RESULTADO FINAL e linhas de total.
- Valores negativos da planilha antiga viram valores positivos de despesa.
- Sem migration nova.

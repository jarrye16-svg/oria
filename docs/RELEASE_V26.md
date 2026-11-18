# Oria — estabilização v26

## Atualização do banco

As migrações 0020, 0021 e 0022 foram aprovadas pelo proprietário e aplicadas em 18/11/2026. A correção adicional 0023 também foi aprovada e aplicada depois de um teste revelar ambiguidade na referência expires_at da função antiga de convites. Não reaplicar as migrações iniciais nem apagar tabelas. A 0021 reúne a restauração dos recursos de 0017–0019 e trata a alteração da assinatura da função de códigos entre versões.

- 0020: vínculo dos depósitos com as entradas; sincronização transacional, estorno, rejeição de saldo negativo, preservação da data de pagamento e pagamento de fatura em lote.
- 0021: restauração dos códigos/links e remoção de membros. Mantém autorização de administrador e serializa o consumo de um convite para impedir dois aceites simultâneos.
- 0022: restauração transacional dos lançamentos CSV na mesma casa, sujeita às permissões existentes.
- 0023: qualifica a referência à validade dos convites e serializa gerações na mesma casa.

Nenhuma migração usa DROP TABLE, TRUNCATE ou altera valores financeiros de maneira global. A 0020 associa depósitos históricos a entradas apenas se o vínculo for único. Casos ambíguos ficam bloqueados para alteração/exclusão financeira até conciliação; não devem ser corrigidos por adivinhação. Os gatilhos de estorno podem impedir uma edição/exclusão se o saldo do porquinho já foi consumido.

O cliente antigo pode enviar o depósito de entrada separadamente; a 0020 ignora essa duplicação apenas para o mesmo depósito vinculado recente e com a anotação reservada. Publicar o cliente atualizado logo após a atualização do banco.

## Comportamento do app

- Dinheiro não é reformatado a cada tecla; aceita decimal brasileiro, valores com ponto decimal e agrupamento brasileiro.
- Formatos inválidos não viram outro valor. O sinal negativo é preservado pelo conversor e rejeitado nos formulários que só aceitam valores positivos.
- Receitas recorrentes/duplicadas começam como pendentes; confirmação de recebimento é explícita.
- Saldo realizado significa receitas recebidas menos despesas pagas no mês, sem afirmar que corresponde a todo o saldo bancário disponível.
- CSV exporta lançamentos de todos os meses, incluindo vínculos, observações, situação e data de pagamento; não é uma cópia integral do banco. A importação exige a mesma casa e os cartões/categorias/porquinhos vinculados existentes, mostra prévia e atualiza os mesmos identificadores sem apagar outros lançamentos.
- Usuário pode sair/trocar de conta no fluxo inicial; erros de leitura não se passam por ausência de casa.

## Validação

- Executado localmente: 48 verificações de valores, e-mails, UUIDs e CSV, inclusive campos com aspas/quebras de linha, datas inválidas, outra casa e identificadores repetidos.
- Executado: formatação dos arquivos Dart alterados, conferência de espaços no diff e análise estática do módulo CSV.
- Preparado: testes de estado de autenticação e edição monetária em Flutter e fluxo de CI com teste/análise/build sem publicação automática.
- Executado no banco ativo: testes transacionais de depósito, edição, estorno, saldo insuficiente, preservação da data, pagamento em lote, CSV idempotente, rejeição de outra casa, geração/aceite de códigos e links e preservação do administrador. Toda a rodada passou e as fixtures foram desfeitas com ROLLBACK.
- Pendente: testes completos do Flutter e build no GitHub Actions, seguidos de teste ponta a ponta do aplicativo.

Na consulta do banco ativo não foi encontrada conta com e-mail começando por teste. A função create_house_with_defaults passou em um teste direto em transação desfeita. Portanto, a interpretação anterior de cadastro concluído com teste@teste.com não está confirmada no banco; o acesso exibido anteriormente precisa ser revalidado em uma nova sessão.

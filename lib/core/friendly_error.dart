String friendlyError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('saldo insuficiente'))
    return 'Saldo insuficiente no porquinho para concluir esta alteração.';
  if (text.contains('conciliada'))
    return 'Esta entrada antiga precisa ser conciliada com o porquinho antes de alterar o valor.';
  if (text.contains('expirado') ||
      text.contains('invalido') ||
      text.contains('inválido'))
    return 'Os dados são inválidos ou o convite expirou. Confira e tente novamente.';
  if (text.contains('administrador') ||
      text.contains('sem acesso') ||
      text.contains('permission') ||
      text.contains('permissão'))
    return 'Você não tem permissão para concluir esta ação.';
  return 'Não consegui concluir agora. Confira sua conexão e tente novamente.';
}

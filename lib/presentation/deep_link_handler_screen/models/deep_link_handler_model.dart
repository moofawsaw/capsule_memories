class DeepLinkHandlerModel {
  final String type;
  final String code;
  final String? pendingAction;

  DeepLinkHandlerModel({
    required this.type,
    required this.code,
    this.pendingAction,
  });

  DeepLinkHandlerModel copyWith({
    String? type,
    String? code,
    String? pendingAction,
  }) {
    return DeepLinkHandlerModel(
      type: type ?? this.type,
      code: code ?? this.code,
      pendingAction: pendingAction ?? this.pendingAction,
    );
  }
}

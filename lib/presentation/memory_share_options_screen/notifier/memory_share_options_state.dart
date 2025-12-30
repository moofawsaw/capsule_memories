import 'package:flutter/foundation.dart';
import '../models/memory_share_options_model.dart';

@immutable
class MemoryShareOptionsState {
  final MemoryShareOptionsModel model;

  const MemoryShareOptionsState({
    required this.model,
  });

  MemoryShareOptionsState copyWith({
    MemoryShareOptionsModel? model,
  }) {
    return MemoryShareOptionsState(
      model: model ?? this.model,
    );
  }
}

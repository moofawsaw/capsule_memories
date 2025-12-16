import '../../../core/app_export.dart';

/// This class is used in the [splash_screen] screen.

// ignore_for_file: must_be_immutable
class SplashModel extends Equatable {
  SplashModel({this.logoImagePath, this.id}) {
    logoImagePath = logoImagePath ?? ImageConstant.imgLogo;
    id = id ?? "";
  }

  String? logoImagePath;
  String? id;

  SplashModel copyWith({
    String? logoImagePath,
    String? id,
  }) {
    return SplashModel(
      logoImagePath: logoImagePath ?? this.logoImagePath,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [logoImagePath, id];
}

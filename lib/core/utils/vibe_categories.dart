class VibeCategory {
  final String name;
  final String imagePath;
  final String description;

  const VibeCategory({
    required this.name,
    required this.imagePath,
    required this.description,
  });
}

class VibeCategories {
  static const fun = VibeCategory(
    name: 'Fun',
    imagePath: 'assets/images/img_group.png',
    description: 'Upbeat and cheerful vibes',
  );

  static const crazy = VibeCategory(
    name: 'Crazy',
    imagePath: 'assets/images/img_group_orange_600.png',
    description: 'Wild and energetic vibes',
  );

  static const sexy = VibeCategory(
    name: 'Sexy',
    imagePath: 'assets/images/img_group_orange_600_34x36.png',
    description: 'Sultry and smooth vibes',
  );

  static const cute = VibeCategory(
    name: 'Cute',
    imagePath: 'assets/images/img_group_34x36.png',
    description: 'Sweet and adorable vibes',
  );

  static List<VibeCategory> get all => [
        fun,
        crazy,
        sexy,
        cute,
      ];

  static VibeCategory getByName(String name) {
    return all.firstWhere(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
      orElse: () => fun,
    );
  }
}

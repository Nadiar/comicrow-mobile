class DivinaPage {
  const DivinaPage({
    required this.href,
    required this.index,
    this.type,
    this.width,
    this.height,
  });

  final String href;
  final int index;
  final String? type;
  final int? width;
  final int? height;
}

class DivinaManifest {
  const DivinaManifest({
    required this.title,
    required this.pages,
  });

  final String title;
  final List<DivinaPage> pages;
}

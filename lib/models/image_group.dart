class OverlayImage {
  final String fileName;
  final String label;
  OverlayImage(this.fileName, this.label);
}

class ImageGroup {
  final String title;
  final String baseImage;
  final List<OverlayImage> overlays;

  ImageGroup({
    required this.title,
    required this.baseImage,
    required this.overlays,
  });
}



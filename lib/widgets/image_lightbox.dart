import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Opens [imageUrl] in a focused, centered lightbox.
///
/// The rest of the app is pushed back behind a blurred, dimmed scrim so the
/// photo is the only thing in focus. The image is shown in full (letterboxed,
/// never cropped) and can be pinch / scroll zoomed. Tapping the scrim or the
/// close button dismisses it.
Future<void> showImageLightbox(
  BuildContext context, {
  required String imageUrl,
  String? caption,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close image',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => _ImageLightbox(
      imageUrl: imageUrl,
      caption: caption,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ImageLightbox extends StatelessWidget {
  const _ImageLightbox({required this.imageUrl, this.caption});

  final String imageUrl;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        // Blur + dim everything behind the image so it holds full focus.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.white.withOpacity(0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: media.size.height * 0.72,
                          maxWidth: media.size.width,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 180,
                                width: 180,
                                child: Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 180,
                              width: 180,
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (caption != null && caption!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Pinch or scroll to zoom · tap outside to close',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

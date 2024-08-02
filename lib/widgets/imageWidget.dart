import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart' as nativeW;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  final String url;
  final double height;

  const ImageWidget({super.key,required this.url,required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CachedNetworkImage(
        imageUrl: url,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );

  }

}

class ImageMessageWidget extends StatelessWidget {
  final String? url;
  final nativeW.Uint8List? data;
  final double height;

  const ImageMessageWidget({super.key,this.data,this.url,required this.height});

  @override
  Widget build(BuildContext context) {
    if(url != null) {
      return SizedBox(
        height: height,
        child: CachedNetworkImage(
          imageUrl: url!,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Image.memory(data! as Uint8List),
    );

  }

}
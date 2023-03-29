import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;

final imageProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, url) async {
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  },
);

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        body: ImagesGrid(),
      ),
    );
  }
}

class ImagesGrid extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 24,
      itemBuilder: (context, index) {
        final images = ref
            .watch(imageProvider('https://source.unsplash.com/random?$index'));
        return images.when(
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Error loading images')),
          data: (imageData) {
            return Center(
              child: InkWell(
                onTap: () async {
                  final directory = await path.getTemporaryDirectory();
                  final fileName = 'image_$index.jpg';
                  final file =
                      await File('${directory.path}/$fileName').create();
                  file.writeAsBytesSync(imageData);
                  downloadImage(file, fileName);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.memory(imageData, fit: BoxFit.fill),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> downloadImage(File file, String? name) async {
    if (file != null && file.path != null) {
      GallerySaver.saveImage(file.path).then((value) {
        log("Downloaded");
      });
    }
  }
}

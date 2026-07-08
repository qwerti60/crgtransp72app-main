import 'package:crgtransp72app/api/service_images_api.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyAppI());

class MyAppI extends StatelessWidget {
  const MyAppI({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gallery App',
      home: GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State {
  late Future<List<ServiceImageItem>> images;

  @override
  void initState() {
    super.initState();
    images = ServiceImagesApi.fetch('vidt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: FutureBuilder<List<ServiceImageItem>>(
        future: images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            final items = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: ServiceImagePreview(
                          item: items[index],
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: Text(items[index].name),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenCarousel extends StatelessWidget {
  final List<String> imageLinks;

  const FullScreenCarousel({super.key, required this.imageLinks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.grey[300], // Icône en gris clair
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            enableInfiniteScroll: true,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 2), // Défilement automatique après 2 secondes
          ),
          items: imageLinks.map<Widget>((imageUrl) {
            return InteractiveViewer(
              panEnabled: true, // Permet de déplacer l'image
              minScale: 0.8,    // Zoom minimal
              maxScale: 4.0,    // Zoom maximal
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: imageUrl.startsWith('data:image/png;base64,')
            ? Image.memory(
                base64Decode(imageUrl.split(',')[1]),
                fit: BoxFit.contain,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


/// Identixia company logo — same asset as Android / RN demos.
class IdentixiaLogo extends StatelessWidget {
  const IdentixiaLogo({
    super.key,
    this.size = 120,
    this.onPressed,
  });


  final double size;
  final VoidCallback? onPressed;


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 48;
    assert(size > 0);
    final image = Image.asset(
      'assets/images/ic_identixia.png',
      width: width,
      height: 72,
      fit: BoxFit.contain,
      semanticLabel: 'Identixia',
    );


    if (onPressed == null) {
      return Center(child: image);
    }


    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: image,
      ),
    );
  }


  static Future<void> openWebsite() {
    return launchUrl(Uri.parse('https://identixia.com'));
  }
}

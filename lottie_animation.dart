import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pastor_stays/utils/image_utils.dart';

class LottieAnimation extends StatefulWidget {
  const LottieAnimation({Key? key}) : super(key: key);

  @override
  State<LottieAnimation> createState() => _LottieAnimationState();
}

class _LottieAnimationState extends State<LottieAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.asset(
        ImageUtils.noDataFound,


        height: 40,
        width: 40,
      ),
    );
  }
}

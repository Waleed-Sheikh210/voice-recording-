import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pastor_stays/utils/extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../Services/user_service.dart';
import '../../utils/color_utils.dart';
import '../../utils/image_utils.dart';
import 'flow_shader.dart';
import 'globals.dart';
import 'lottie_animation.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    Key? key,
    required this.controller,
    required this.chatId, required this.otherId,
  }) : super(key: key);

  final AnimationController controller;
  final String chatId;
  final String otherId;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static const double size = 55;
  double movementInt = 0.0;
  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  Record record = Record();

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * Globals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    record.dispose();
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        lockSlider(),
        cancelSlider(),
        audioButton(),
        if (isLocked) timerLocked(),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned(
      bottom: -lockerAnimation.value - 20,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          // color: ColorUtils.field_background,
          color: ColorUtils.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const FaIcon(FontAwesomeIcons.lock, size: 20),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation.value - 1,
      bottom: -3,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: ColorUtils.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie ? const LottieAnimation() : Text(recordDuration),
              const SizedBox(width: size),
              FlowShader(
                child: Row(
                  children: const [
                    Icon(Icons.keyboard_arrow_left),
                    Text("Slide to cancel")
                  ],
                ),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
               SizedBox(width: size),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return Positioned(
      right: -15,
      bottom: -3,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 25),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              Vibrate.feedback(FeedbackType.success);
              timer?.cancel();
              timer = null;
              startTime = null;
              recordDuration = "00:00";

              // var filePath = await Record().stop();
              // Globals.globalPath = filePath.toString().trim();
              var filePath = await Record().stop();
              Globals.globalPath = filePath.toString().trim();
             
              debugPrint(filePath);
              setState(() {
                isLocked = false;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(recordDuration),
                FlowShader(
                  child: const Text("Tap lock to stop"),
                  duration: const Duration(seconds: 3),
                  flowColors: const [Colors.white, Colors.grey],
                ),
                Center(
                  child: FaIcon(
                    FontAwesomeIcons.lock,
                    size: 18,
                    color: ColorUtils.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: LongPressDraggable(
        axis: Axis.horizontal,
          feedback: Icon(Icons.mic),
          childWhenDragging: SizedBox(),
          onDragEnd: (details) async {
            if (isCancelled(details.offset, context)) {
              Vibrate.feedback(FeedbackType.heavy);

              timer?.cancel();
              timer = null;
              startTime = null;
              recordDuration = "00:00";

              setState(() {
                showLottie = true;
              });

              Timer(const Duration(milliseconds: 1440), () async {
                widget.controller.reverse();
                debugPrint("Cancelled recording");
                var filePath = await record.stop();
                debugPrint(filePath);
                File(filePath.toString()).delete();
                debugPrint("Deleted $filePath");
                showLottie = false;
              });
            }
            else if (checkIsLocked(details.offset)) {
              widget.controller.reverse();

              Vibrate.feedback(FeedbackType.heavy);
              debugPrint("Locked recording");
              debugPrint(details.offset.dy.toString());
              setState(() {
                isLocked = true;
              });
            }
            else {
              widget.controller.reverse();

              Vibrate.feedback(FeedbackType.success);

              timer?.cancel();
              timer = null;
              startTime = null;
              recordDuration = "00:00";

              var filePath = await Record().stop();
              Globals.globalPath = filePath.toString().trim();

              // AudioState.files.add(filePath!);
              // Globals.audioListKey.currentState!
              //     .insertItem(AudioState.files.length - 1);
              debugPrint(filePath);
            }
          },
          onDragStarted: () {
            print("123");
          },onDragUpdate: (details) {
            print(details.localPosition.dx);
            if(details.localPosition.dx <200){
              print("ASBDVAJSDASBFGASCV,");
              Vibrate.feedback(FeedbackType.heavy);

              timer?.cancel();
              timer = null;
              startTime = null;
              recordDuration = "00:00";

              setState(() {
                showLottie = true;
              });

              Timer(const Duration(milliseconds: 1440), () async {
                widget.controller.reverse();
                debugPrint("Cancelled recording");
                var filePath = await record.stop();
                debugPrint(filePath);
                File(filePath.toString()).delete();
                debugPrint("Deleted $filePath");
                showLottie = false;
              });
            }
          },
          child: Icon(Icons.mic)),
      onLongPressDown: (_) {

        debugPrint("onLongPressDown");
        widget.controller.forward();
      },
      onHorizontalDragEnd: (details) {
        print(details. primaryVelocity);
setState(() {

});
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          print(details.globalPosition.dx.toInt());


        });
      },

    onHorizontalDragStart: (details) => print(details.localPosition.dx),
      onLongPressEnd: (details) async {
        debugPrint("onLongPressEnd");
print(details.globalPosition.dx);
setState(() {

});
        if (isCancelled(details.localPosition, context)) {
          Vibrate.feedback(FeedbackType.heavy);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();
            debugPrint("Cancelled recording");
            var filePath = await record.stop();
            debugPrint(filePath);
            File(filePath.toString()).delete();
            debugPrint("Deleted $filePath");
            showLottie = false;
          });
        }
        else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();

          Vibrate.feedback(FeedbackType.heavy);
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        }
        else {
          widget.controller.reverse();

          Vibrate.feedback(FeedbackType.success);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";

          var filePath = await Record().stop();
          Globals.globalPath = filePath.toString().trim();

          // AudioState.files.add(filePath!);
          // Globals.audioListKey.currentState!
          //     .insertItem(AudioState.files.length - 1);
          debugPrint(filePath);
        }
      },
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onTapDown: (TapDownDetails details) => _onTapDown(details),
      onLongPressMoveUpdate: (details) {
        print("<<<<<${details.localPosition.dx.toDouble()}>>>>>");
        movementInt = details.localPosition.dx.toDouble();
      },
      onLongPress: () async {
        debugPrint("onLongPress");
        Vibrate.feedback(FeedbackType.success);
        if (await Record().hasPermission()) {
          record = Record();
          var name  = "";
          if(Platform.isAndroid){
            Globals.documentPath = '/storage/emulated/0/Download/';
          }
          else{
            Directory directory = await getApplicationDocumentsDirectory();
            Globals.documentPath = directory.path.toString().trim() + "/";
          }
          name = Globals.documentPath +
              "audio_${DateTime.now().millisecondsSinceEpoch}.m4a";
          var file = File(name);
          if (await file.exists()) {
            await record.start(
              path: name,
              encoder: AudioEncoder.aacLc,
            );
          }
          else{
            if(await Permission.storage.status == PermissionStatus.granted){
              print("NO FILE ERROR");
              await record.start(
                path: name,
                encoder: AudioEncoder.aacLc,
              );
            }

          }

          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            String min = minDur < 10 ? "0$minDur" : minDur.toString();
            String sec = secDur < 10 ? "0$secDur" : secDur.toString();
            setState(() {
              recordDuration = "$min:$sec";
            });
          });
        }
        else{

        }
      },
    );
  }
  double bar2Position = 180.0;

  _onTapDown(TapDownDetails details) {
    var x = details.globalPosition.dx;
    print("tap down " + x.toString());
    setState(() {
      bar2Position = x;
      print(bar2Position);
    });
  }
  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}





class WaveSlider extends StatefulWidget {


  int? numberOfBars;

  WaveSlider({ this.numberOfBars });


  @override
  State<StatefulWidget> createState() => WaveSliderState();
}


class WaveSliderState extends State<WaveSlider> {
  double bar2Position = 180.0;
  List<int> bars = [] ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    for (var i = 0 ; i <= widget.numberOfBars! ; i++) {
      bars.add(i);
      print("Called");
      setState((){});
    }
  }

  _onTapDown(TapDownDetails details) {
    var x = details.globalPosition.dx;
    print("tap down " + x.toString());
    setState(() {
      bar2Position = x;
    });
  }

  @override
  Widget build(BuildContext context) {
    int barItem = 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            GestureDetector(
              onTapDown: (TapDownDetails details) => _onTapDown(details),
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                setState(() {
                  bar2Position = details.globalPosition.dx;
                  print(bar2Position);
                });
              },
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: bars.map((int height) {
                    Gradient color = barItem + 1 <= bar2Position / height * 1.7
                        ? LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.orange,
                        Colors.orangeAccent,
                      ],
                    )
                        : LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.fromRGBO(37, 36, 44, 0.2),
                        Color.fromRGBO(37, 36, 44, 0.2)
                      ],
                    );
                    barItem++;
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: color
                              // color: color,
                            ),
                            height: 35.0.h,
                            width: 8.w,
                          ),
                          SizedBox(width: 5,)
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_player/video_player.dart';

const _seenKey = 'intro_seen';
const _storage = FlutterSecureStorage();

/// True when the opening video was already shown on this device.
Future<bool> introSeen() async {
  try {
    return await _storage.read(key: _seenKey) == '1';
  } catch (_) {
    return true;
  }
}

/// Stand-alone root for the first-launch video.
///
/// It runs outside the app's DesignCanvas on purpose: on web the video is
/// an HTML element, and the canvas's scale transform misplaces it.
class IntroApp extends StatelessWidget {
  const IntroApp({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ضوجة',
    theme: ThemeData(fontFamily: 'Plex'),
    home: IntroVideo(onDone: onDone),
  );
}

class IntroVideo extends StatefulWidget {
  const IntroVideo({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<IntroVideo> {
  final _video = VideoPlayerController.asset('assets/video/dooja.mp4');
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _video.addListener(_onTick);
    _start();
  }

  Future<void> _start() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      setState(() {});
      // Browsers block autoplay with sound.
      if (kIsWeb) await _video.setVolume(0);
      // play() can stay pending until the browser allows playback,
      // so don't block the first frame on it.
      unawaited(_video.play().catchError((_) {}));
    } catch (_) {
      _finish();
    }
  }

  void _onTick() {
    final v = _video.value;
    if (v.hasError ||
        v.isInitialized &&
            v.duration > Duration.zero &&
            v.position >= v.duration - const Duration(milliseconds: 150)) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    _video.removeListener(_onTick);
    if (_video.value.isPlaying) unawaited(_video.pause());
    try {
      await _storage.write(key: _seenKey, value: '1');
    } catch (_) {}
    widget.onDone();
  }

  @override
  void dispose() {
    _video.removeListener(_onTick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video.value;
    return Scaffold(
      body: DecoratedBox(
        // Matches the video's own top and bottom edges.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCFAFD), Color(0xFFEFE9F3)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // On web the video is an HTML <video> at 100% size, which the
            // browser letterboxes itself; give it the whole screen at
            // offset zero, since offset platform views are misplaced.
            if (v.isInitialized && kIsWeb)
              Positioned.fill(child: VideoPlayer(_video))
            else if (v.isInitialized)
              LayoutBuilder(
                builder: (_, bc) {
                  var w = bc.maxWidth, h = w / v.aspectRatio;
                  if (h > bc.maxHeight) {
                    h = bc.maxHeight;
                    w = h * v.aspectRatio;
                  }
                  return Center(
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: VideoPlayer(_video),
                    ),
                  );
                },
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black38,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

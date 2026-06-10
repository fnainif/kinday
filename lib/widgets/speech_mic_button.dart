import 'package:flutter/material.dart';

class SpeechMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? inactiveColor;

  const SpeechMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<SpeechMicButton> createState() => _SpeechMicButtonState();
}

class _SpeechMicButtonState extends State<SpeechMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SpeechMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.redAccent;
    final inactiveColor = widget.inactiveColor ?? Colors.indigo.shade300;

    return GestureDetector(
      onTap: widget.onTap,
      child: widget.isListening
          ? AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scale: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                );
              },
            )
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: inactiveColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.mic_none_outlined,
                color: inactiveColor,
                size: 18,
              ),
            ),
    );
  }
}

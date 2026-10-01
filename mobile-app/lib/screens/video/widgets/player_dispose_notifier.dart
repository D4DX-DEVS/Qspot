import 'package:flutter/widgets.dart';

/// Calls [onDispose] when it leaves the tree, and otherwise just shows
/// [child]. Used to learn that a video player widget (and the web view inside
/// it) has been destroyed while its controller lives on.
class PlayerDisposeNotifier extends StatefulWidget {
  const PlayerDisposeNotifier({
    super.key,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<PlayerDisposeNotifier> createState() => _PlayerDisposeNotifierState();
}

class _PlayerDisposeNotifierState extends State<PlayerDisposeNotifier> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

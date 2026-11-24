import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

import '../colors.dart';
import '../previews.dart';
import '../type.dart';

/// On the web, [Link] is an `<a href>`, so the browser can open the link in
/// a new tab or copy its address.
class TextLink extends StatefulWidget {
  const TextLink(this.text, {super.key, this.uri});

  final String text;
  final Uri? uri;

  @override
  State<TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<TextLink> {
  var _hasFocusHighlight = false;

  @override
  Widget build(BuildContext context) {
    final style = context.type.body.copyWith(
      color: SiteColors.signalAmber,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: SiteColors.signalAmber,
    );
    return Link(
      uri: widget.uri,
      builder: (context, followLink) => FocusableActionDetector(
        enabled: followLink != null,
        mouseCursor: followLink == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onShowFocusHighlight: (isShown) =>
            setState(() => _hasFocusHighlight = isShown),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => followLink?.call(),
          ),
        },
        child: GestureDetector(
          onTap: followLink,
          child: CustomPaint(
            foregroundPainter: _hasFocusHighlight
                ? const _FocusHighlightPainter()
                : null,
            child: Text(widget.text, style: style),
          ),
        ),
      ),
    );
  }
}

class _FocusHighlightPainter extends CustomPainter {
  const _FocusHighlightPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(4),
      const Radius.circular(3),
    ),
    Paint()
      ..color = SiteColors.signalAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  @override
  bool shouldRepaint(_FocusHighlightPainter oldDelegate) => false;
}

@ReadingPreview('TextLink')
Widget textLinkPreview() =>
    TextLink('[Download the CV, PDF]', uri: Uri.parse('https://example.com'));

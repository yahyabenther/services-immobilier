import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Listing text is untrusted user content: rendered as plain text, paragraph
/// breaks preserved, with a working Read more / Read less.
class ExpandableDescription extends StatefulWidget {
  const ExpandableDescription({super.key, required this.text, this.collapsedLines = 5});

  final String text;
  final int collapsedLines;

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 14, height: 1.5, color: AppColors.text);
    final text = widget.text.trim();
    if (text.isEmpty) {
      return const Text('No description provided.', style: TextStyle(fontSize: 14, color: AppColors.muted));
    }

    return LayoutBuilder(builder: (context, c) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: widget.collapsedLines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: c.maxWidth);
      final overflows = painter.didExceedMaxLines;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          text,
          style: style,
          maxLines: _expanded ? null : widget.collapsedLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (overflows)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
            child: Text(_expanded ? 'Read less' : 'Read more'),
          ),
      ]);
    });
  }
}

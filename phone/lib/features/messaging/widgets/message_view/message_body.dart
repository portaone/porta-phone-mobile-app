import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class MessageBody extends StatelessWidget {
  const MessageBody({required this.text, required this.isMine, this.style, super.key});

  final String text;
  final bool isMine;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = this.style ?? theme.contentStyle;
    final previewDecoration = theme.roundQuoteDecoration(isMine);
    final quoteDecoration = theme.strongQuoteDecoration(isMine);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinkPreviewBuilder(
          text: text,
          builder: (context, preview, _) => LinkPreviewReveal(
            preview: preview,
            card: (preview) => Container(
              decoration: previewDecoration,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (preview.image != null) ...[LinkPreviewImage(preview.image!), const SizedBox(height: 8)],
                  if (preview.title != null) ...[
                    Text(preview.title!, style: style.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  if (preview.description != null) ...[
                    Text(preview.description!, style: style),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
        FormattedText(
          text: text,
          style: style.copyWith(fontFamily: theme.textTheme.bodyMedium?.fontFamily, overflow: .ellipsis),
          quoteDecoration: quoteDecoration,
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      ],
    );
  }
}

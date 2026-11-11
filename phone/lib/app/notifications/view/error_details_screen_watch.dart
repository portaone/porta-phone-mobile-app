import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../models/models.dart';

/// The details of an error on a watch face: the error's title and its fields
/// as label-over-value rows that scroll; sharing them and the log console
/// stay on the phone.
class ErrorDetailsScreenWatch extends StatelessWidget {
  const ErrorDetailsScreenWatch({super.key, required this.title, required this.fields});

  final String title;
  final List<ErrorFieldModel> fields;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchScrollList.builder(
        title: title,
        spacing: context.adaptiveMetrics.gap,
        itemCount: fields.length,
        itemBuilder: (context, index) => WatchInfoRow(label: fields[index].title, value: fields[index].details),
      ),
    );
  }
}

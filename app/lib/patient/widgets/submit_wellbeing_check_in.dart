import 'package:atk/patient/bloc/wellbeing_cubit.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

Future<void> submitWellbeingCheckIn(BuildContext context, String topic) async {
  try {
    final responses = await context.read<WellbeingCubit>().save(topic);
    if (!context.mounted || responses == null) return;
    await Navigator.pushNamed(context, '/${topic}_next', arguments: responses);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save your check-in. Try again.')),
    );
  }
}

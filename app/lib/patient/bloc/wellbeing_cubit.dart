import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/services/api_client.dart';

typedef WellbeingState = ({Map<String, String> responses, bool saving});

class WellbeingCubit extends Cubit<WellbeingState> {
  WellbeingCubit() : super((responses: const {}, saving: false));

  void select(String key, String value) {
    if (state.saving) return;
    emit((responses: {...state.responses, key: value}, saving: false));
  }

  Future<Map<String, String>?> save(String topic) async {
    if (state.saving) return null;
    final responses = state.responses;
    emit((responses: responses, saving: true));
    try {
      await ApiClient.saveWellbeingCheckIn(topic, responses);
      return responses;
    } finally {
      if (!isClosed) emit((responses: responses, saving: false));
    }
  }
}

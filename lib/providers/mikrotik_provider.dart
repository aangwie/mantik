import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/routeros_client_helper.dart';
import '../models/login_profile_model.dart';

final mikrotikClientProvider = Provider<RouterOsClientHelper>((ref) {
  return RouterOsClientHelper();
});

final connectionStateProvider = NotifierProvider<ConnectionStateNotifier, bool>(() {
  return ConnectionStateNotifier();
});

class ConnectionStateNotifier extends Notifier<bool> {
  LoginProfile? currentProfile;

  @override
  bool build() {
    return false;
  }

  Future<bool> connect(LoginProfile profile) async {
    final client = ref.read(mikrotikClientProvider);
    final success = await client.connect(profile);
    if (success) {
      currentProfile = profile;
    }
    state = success;
    return success;
  }

  void disconnect() {
    final client = ref.read(mikrotikClientProvider);
    client.disconnect();
    currentProfile = null;
    state = false;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/login_profile_model.dart';
import '../data/database_helper.dart';

final loginProfilesProvider = NotifierProvider<LoginProfilesNotifier, List<LoginProfile>>(() {
  return LoginProfilesNotifier();
});

class LoginProfilesNotifier extends Notifier<List<LoginProfile>> {
  @override
  List<LoginProfile> build() {
    loadProfiles();
    return [];
  }

  Future<void> loadProfiles() async {
    final profiles = await DatabaseHelper.instance.readAllProfiles();
    state = profiles;
  }

  Future<void> addProfile(LoginProfile profile) async {
    await DatabaseHelper.instance.create(profile);
    await loadProfiles();
  }

  Future<void> updateProfile(LoginProfile profile) async {
    await DatabaseHelper.instance.update(profile);
    await loadProfiles();
  }

  Future<void> deleteProfile(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadProfiles();
  }
}

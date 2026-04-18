import 'package:router_os_client/router_os_client.dart';
import '../models/login_profile_model.dart';

class RouterOsClientHelper {
  RouterOSClient? _client;

  Future<bool> connect(LoginProfile profile) async {
    try {
      _client = RouterOSClient(
        address: profile.host,
        user: profile.username,
        password: profile.password,
        port: profile.port,
      );
      
      final isConnected = await _client!.login();
      return isConnected;
    } catch (e) {
      // Failed to connect
      return false;
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
  }

  Future<List<Map<String, String>>> getPppoeSecrets() async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/ppp/secret/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getPppoeActive() async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/ppp/active/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getPppoeProfiles() async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/ppp/profile/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getInterfaces() async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/interface/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getInterfaceTraffic(String interface) async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk([
        '/interface/monitor-traffic',
        '=interface=$interface',
        '=once='
      ]);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }
  
  Future<List<Map<String, String>>> getSimpleQueues() async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/queue/simple/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>?> getQueueTraffic(String name) async {
    if (_client == null) return null;
    try {
      var result = await _client!.talk([
        '/queue/simple/print',
        '=stats=',
        '=?name=$name'
      ]);
      final parsed = _parseResult(result);
      if (parsed.isNotEmpty) return parsed.first;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> enablePppoeSecret(String id) async {
    if (_client == null) return false;
    try {
      await _client!.talk(['/ppp/secret/enable', '=.id=$id']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disablePppoeSecret(String id) async {
    if (_client == null) return false;
    try {
      await _client!.talk(['/ppp/secret/disable', '=.id=$id']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePppoeSecret(String id) async {
    if (_client == null) return false;
    try {
      await _client!.talk(['/ppp/secret/remove', '=.id=$id']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addPppoeSecret(String name, String password, String service, String profile) async {
    if (_client == null) return false;
    try {
      await _client!.talk([
        '/ppp/secret/add',
        '=name=$name',
        '=password=$password',
        '=service=$service',
        '=profile=$profile'
      ]);
      return true;
    } catch (e) {
       return false;
    }
  }

  Future<bool> editPppoeSecret(String id, String name, String password, String service, String profile) async {
    if (_client == null) return false;
    try {
      List<String> command = [
        '/ppp/secret/set',
        '=.id=$id',
        '=name=$name',
        '=service=$service',
        '=profile=$profile'
      ];
      if (password.isNotEmpty) {
        command.add('=password=$password');
      }
      await _client!.talk(command);
      return true;
    } catch (e) {
       return false;
    }
  }

  // --- FIREWALL APIS ---

  Future<List<Map<String, String>>> getFirewallRules(String type) async {
    if (_client == null) return [];
    try {
      var result = await _client!.talk(['/ip/firewall/$type/print']);
      return _parseResult(result);
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleFirewallRule(String type, String id, bool enable) async {
    if (_client == null) return false;
    final act = enable ? 'enable' : 'disable';
    try {
      await _client!.talk(['/ip/firewall/$type/$act', '=.id=$id']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFirewallRule(String type, String id) async {
    if (_client == null) return false;
    try {
      await _client!.talk(['/ip/firewall/$type/remove', '=.id=$id']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveFirewallRule(String type, Map<String, String> data, {String? id}) async {
    if (_client == null) return false;
    try {
      String action = id == null ? 'add' : 'set';
      List<String> command = ['/ip/firewall/$type/$action'];
      
      if (id != null) {
        command.add('=.id=$id');
      }
      
      data.forEach((key, value) {
        if (value.isNotEmpty) {
          command.add('=$key=$value');
        }
      });
      
      await _client!.talk(command);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, String>> _parseResult(dynamic rawResult) {
    // router_os_client typically returns a list of dictionaries.
    // Ensure casting type correctness.
    final resultList = <Map<String, String>>[];
    if (rawResult is List) {
       for(var item in rawResult) {
          if (item is Map) {
             resultList.add(item.map((key, value) => MapEntry(key.toString(), value.toString())));
          }
       }
    }
    return resultList;
  }
}

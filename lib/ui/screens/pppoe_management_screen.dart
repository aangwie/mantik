import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mikrotik_provider.dart';

class PppoeManagementScreen extends StatelessWidget {
  const PppoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PPPoE Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Secrets'),
              Tab(text: 'Profiles'),
              Tab(text: 'Active Connections'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PppoeSecretsTab(),
            PppoeProfilesTab(),
            PppoeActiveTab(),
          ],
        ),
      ),
    );
  }
}

// --- SECRETS TAB ---
class PppoeSecretsTab extends ConsumerStatefulWidget {
  const PppoeSecretsTab({super.key});
  @override
  ConsumerState<PppoeSecretsTab> createState() => _PppoeSecretsTabState();
}

class _PppoeSecretsTabState extends ConsumerState<PppoeSecretsTab> {
  List<Map<String, String>> _secrets = [];
  List<Map<String, String>> _activePppoes = [];
  List<Map<String, String>> _profiles = [];
  String _filter = 'All'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSecrets();
  }

  Future<void> _fetchSecrets() async {
    setState(() => _isLoading = true);
    final client = ref.read(mikrotikClientProvider);
    final active = await client.getPppoeActive();
    final secrets = await client.getPppoeSecrets();
    final profiles = await client.getPppoeProfiles();
    if (mounted) {
      setState(() {
        _activePppoes = active;
        _secrets = secrets;
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> get _filteredSecrets {
    if (_filter == 'All') return _secrets;
    final activeNames = _activePppoes.map((a) => a['name']).toSet();
    if (_filter == 'Active') {
      return _secrets.where((s) => activeNames.contains(s['name'])).toList();
    } else {
      return _secrets.where((s) => !activeNames.contains(s['name'])).toList();
    }
  }

  Future<void> _toggleEnableDisable(Map<String, String> secret) async {
    final client = ref.read(mikrotikClientProvider);
    final id = secret['.id'];
    if (id == null) return;
    
    final isDisabled = secret['disabled'] == 'true';
    if (isDisabled) {
      await client.enablePppoeSecret(id);
    } else {
      await client.disablePppoeSecret(id);
    }
    _fetchSecrets();
  }

  Future<void> _deleteSecret(Map<String, String> secret) async {
    final client = ref.read(mikrotikClientProvider);
    final id = secret['.id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${secret["name"]}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await client.deletePppoeSecret(id);
      if (mounted) _fetchSecrets();
    }
  }

  List<String> get _profileNames {
    List<String> names = _profiles.map((p) => p['name'] ?? 'default').toList();
    if (names.isEmpty) names.add('default');
    return names.toSet().toList();
  }

  void _showFormDialog({Map<String, String>? secret}) {
    final isEdit = secret != null;
    final id = secret?['.id'];
    final nameCtrl = TextEditingController(text: secret?['name'] ?? '');
    final passCtrl = TextEditingController();
    
    final pNames = _profileNames;
    String selectedService = secret?['service'] ?? 'pppoe';
    if (!['any', 'async', 'l2tp', 'ovpn', 'pppoe', 'pptp', 'sstp'].contains(selectedService)) selectedService = 'pppoe';
    
    String selectedProfile = secret?['profile'] ?? 'default';
    if (!pNames.contains(selectedProfile)) selectedProfile = pNames.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(isEdit ? 'Edit PPPoE Secret' : 'Add PPPoE Secret'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (Username)')),
                TextField(
                  controller: passCtrl, 
                  decoration: InputDecoration(labelText: isEdit ? 'Password (leave blank to keep current)' : 'Password'), 
                  obscureText: true
                ),
                DropdownButtonFormField<String>(
                  value: selectedService,
                  decoration: const InputDecoration(labelText: 'Service'),
                  items: ['any', 'async', 'l2tp', 'ovpn', 'pppoe', 'pptp', 'sstp']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setStateBuilder(() { if (val != null) selectedService = val; }),
                ),
                DropdownButtonFormField<String>(
                  value: selectedProfile,
                  decoration: const InputDecoration(labelText: 'Profile'),
                  items: pNames.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setStateBuilder(() { if (val != null) selectedProfile = val; }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                   final client = ref.read(mikrotikClientProvider);
                   if (isEdit && id != null) {
                     await client.editPppoeSecret(id, nameCtrl.text, passCtrl.text, selectedService, selectedProfile);
                   } else {
                     await client.addPppoeSecret(nameCtrl.text, passCtrl.text, selectedService, selectedProfile);
                   }
                   if (ctx.mounted) {
                     Navigator.pop(ctx);
                     _fetchSecrets();
                   }
                }
              },
              child: const Text('Save'),
            )
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        mini: true,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_filteredSecrets.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _filter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Users')),
                        DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filter = val);
                      },
                    ),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSecrets),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchSecrets,
                    child: ListView.builder(
                      itemCount: _filteredSecrets.length,
                      itemBuilder: (ctx, idx) {
                        final s = _filteredSecrets[idx];
                        final isDisabled = s['disabled'] == 'true';
                        final isActive = _activePppoes.any((a) => a['name'] == s['name']);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(child: Text(s['name'] ?? 'Unknown User', style: TextStyle(decoration: isDisabled ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12)),
                                  child: Text(isActive ? 'Active' : 'Offline', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                )
                              ],
                            ),
                            subtitle: Text('Profile: ${s["profile"] ?? "-"} | Service: ${s["service"] ?? "-"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: !isDisabled,
                                  onChanged: (val) => _toggleEnableDisable(s),
                                  activeColor: Colors.blue,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showFormDialog(secret: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSecret(s),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- PROFILES TAB ---
class PppoeProfilesTab extends ConsumerStatefulWidget {
  const PppoeProfilesTab({super.key});
  @override
  ConsumerState<PppoeProfilesTab> createState() => _PppoeProfilesTabState();
}

class _PppoeProfilesTabState extends ConsumerState<PppoeProfilesTab> {
  List<Map<String, String>> _profiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() => _isLoading = true);
    final client = ref.read(mikrotikClientProvider);
    final profiles = await client.getPppoeProfiles();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  void _showFormDialog({Map<String, String>? profile}) {
    final isEdit = profile != null;
    final id = profile?['.id'];
    final nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    final localAddressCtrl = TextEditingController(text: profile?['local-address'] ?? '');
    final remoteAddressCtrl = TextEditingController(text: profile?['remote-address'] ?? '');
    final rateLimitCtrl = TextEditingController(text: profile?['rate-limit'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Profile' : 'Add Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: localAddressCtrl, decoration: const InputDecoration(labelText: 'Local Address')),
              TextField(controller: remoteAddressCtrl, decoration: const InputDecoration(labelText: 'Remote Address')),
              TextField(controller: rateLimitCtrl, decoration: const InputDecoration(labelText: 'Rate Limit (rx/tx)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                 final data = {
                   'name': nameCtrl.text,
                   'local-address': localAddressCtrl.text,
                   'remote-address': remoteAddressCtrl.text,
                   'rate-limit': rateLimitCtrl.text,
                 };
                 final client = ref.read(mikrotikClientProvider);
                 await client.savePppoeProfile(data, id: id);
                 if (ctx.mounted) {
                   Navigator.pop(ctx);
                   _fetchProfiles();
                 }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _deleteProfile(Map<String, String> profile) async {
    final client = ref.read(mikrotikClientProvider);
    final id = profile['.id'];
    final isDefault = profile['default'] == 'true' || profile['name'] == 'default';
    if (id == null || isDefault) return; // Basic protection against deleting default

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete profile ${profile["name"]}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await client.deletePppoeProfile(id);
      if (mounted) _fetchProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        mini: true,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfiles,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _profiles.length,
                itemBuilder: (ctx, idx) {
                  final p = _profiles[idx];
                  final isDefault = p['default'] == 'true' || p['name'] == 'default';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Local: ${p["local-address"] ?? "-"}\n'
                        'Remote: ${p["remote-address"] ?? "-"}\n'
                        'Limit: ${p["rate-limit"] ?? "-"}'
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showFormDialog(profile: p),
                          ),
                          if (!isDefault)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProfile(p),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// --- ACTIVE CONNECTIONS TAB ---
class PppoeActiveTab extends ConsumerStatefulWidget {
  const PppoeActiveTab({super.key});
  @override
  ConsumerState<PppoeActiveTab> createState() => _PppoeActiveTabState();
}

class _PppoeActiveTabState extends ConsumerState<PppoeActiveTab> {
  List<Map<String, String>> _active = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActive();
  }

  Future<void> _fetchActive() async {
    setState(() => _isLoading = true);
    final client = ref.read(mikrotikClientProvider);
    final active = await client.getPppoeActive();
    if (mounted) {
      setState(() {
        _active = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _kickUser(Map<String, String> activeUser) async {
    final client = ref.read(mikrotikClientProvider);
    final id = activeUser['.id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Kick'),
        content: Text('Are you sure you want to disconnect ${activeUser["name"]}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kick', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await client.deletePppoeActive(id);
      if (mounted) _fetchActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchActive,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _active.length,
                itemBuilder: (ctx, idx) {
                  final a = _active[idx];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(a['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      subtitle: Text(
                        'Service: ${a["service"] ?? "-"}\n'
                        'Caller ID (MAC): ${a["caller-id"] ?? "-"}\n'
                        'IP: ${a["address"] ?? "-"}\n'
                        'Uptime: ${a["uptime"] ?? "-"}'
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.output_rounded, color: Colors.red),
                        tooltip: 'Kick Connection',
                        onPressed: () => _kickUser(a),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

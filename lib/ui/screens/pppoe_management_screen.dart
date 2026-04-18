import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mikrotik_provider.dart';

class PppoeManagementScreen extends ConsumerStatefulWidget {
  const PppoeManagementScreen({super.key});

  @override
  ConsumerState<PppoeManagementScreen> createState() => _PppoeManagementScreenState();
}

class _PppoeManagementScreenState extends ConsumerState<PppoeManagementScreen> {
  List<Map<String, String>> _secrets = [];
  List<Map<String, String>> _activePppoes = [];
  String _filter = 'All'; // 'All', 'Active', 'Inactive'
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
    if (mounted) {
      setState(() {
        _activePppoes = active;
        _secrets = secrets;
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
        content: Text('Are you sure you want to delete \${secret["name"]}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await client.deletePppoeSecret(id);
      if (mounted) _fetchSecrets();
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final serviceCtrl = TextEditingController(text: 'pppoe');
    final profileCtrl = TextEditingController(text: 'default');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add PPPoE Secret'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (Username)')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: serviceCtrl, decoration: const InputDecoration(labelText: 'Service')),
              TextField(controller: profileCtrl, decoration: const InputDecoration(labelText: 'Profile')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                 final client = ref.read(mikrotikClientProvider);
                 await client.addPppoeSecret(nameCtrl.text, passCtrl.text, serviceCtrl.text, profileCtrl.text);
                 if (ctx.mounted) {
                   Navigator.pop(ctx);
                   _fetchSecrets();
                 }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, String> secret) {
    final nameCtrl = TextEditingController(text: secret['name']);
    final passCtrl = TextEditingController();
    final serviceCtrl = TextEditingController(text: secret['service'] ?? 'pppoe');
    final profileCtrl = TextEditingController(text: secret['profile'] ?? 'default');
    final id = secret['.id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit PPPoE Secret'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (Username)')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password (leave blank to keep current)'), obscureText: true),
              TextField(controller: serviceCtrl, decoration: const InputDecoration(labelText: 'Service')),
              TextField(controller: profileCtrl, decoration: const InputDecoration(labelText: 'Profile')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && id != null) {
                 final client = ref.read(mikrotikClientProvider);
                 await client.editPppoeSecret(id, nameCtrl.text, passCtrl.text, serviceCtrl.text, profileCtrl.text);
                 if (ctx.mounted) {
                   Navigator.pop(ctx);
                   _fetchSecrets();
                 }
              }
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PPPoE Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() => _filter = val);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Users')),
              const PopupMenuItem(value: 'Active', child: Text('Active Only')),
              const PopupMenuItem(value: 'Inactive', child: Text('Inactive Only')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSecrets),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
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
                            onPressed: () => _showEditDialog(s),
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
    );
  }
}

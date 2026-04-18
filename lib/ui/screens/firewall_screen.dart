import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mikrotik_provider.dart';

class FirewallScreen extends StatelessWidget {
  const FirewallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Firewall Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Filter'),
              Tab(text: 'NAT'),
              Tab(text: 'Mangle'),
              Tab(text: 'RAW'),
              Tab(text: 'Address List'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FirewallListTab(type: 'filter'),
            FirewallListTab(type: 'nat'),
            FirewallListTab(type: 'mangle'),
            FirewallListTab(type: 'raw'),
            FirewallListTab(type: 'address-list'),
          ],
        ),
      ),
    );
  }
}

class FirewallListTab extends ConsumerStatefulWidget {
  final String type;

  const FirewallListTab({super.key, required this.type});

  @override
  ConsumerState<FirewallListTab> createState() => _FirewallListTabState();
}

class _FirewallListTabState extends ConsumerState<FirewallListTab> {
  List<Map<String, String>> _rules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  Future<void> _fetchRules() async {
    setState(() => _isLoading = true);
    final client = ref.read(mikrotikClientProvider);
    final rules = await client.getFirewallRules(widget.type);
    if (mounted) {
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEnableDisable(Map<String, String> rule) async {
    final client = ref.read(mikrotikClientProvider);
    final id = rule['.id'];
    if (id == null) return;
    
    final isDisabled = rule['disabled'] == 'true';
    if (mounted) {
       await client.toggleFirewallRule(widget.type, id, isDisabled);
       _fetchRules();
    }
  }

  Future<void> _deleteRule(Map<String, String> rule) async {
    final client = ref.read(mikrotikClientProvider);
    final id = rule['.id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await client.deleteFirewallRule(widget.type, id);
      if (mounted) _fetchRules();
    }
  }

  void _showFormDialog({Map<String, String>? rule}) {
    final isEdit = rule != null;
    final id = rule?['.id'];
    
    if (widget.type == 'address-list') {
      _showAddressListDialog(isEdit: isEdit, id: id, rule: rule);
    } else {
      _showRuleDialog(isEdit: isEdit, id: id, rule: rule);
    }
  }

  void _showAddressListDialog({required bool isEdit, String? id, Map<String, String>? rule}) {
    final listCtrl = TextEditingController(text: rule?['list'] ?? '');
    final addressCtrl = TextEditingController(text: rule?['address'] ?? '');
    final timeoutCtrl = TextEditingController(text: rule?['timeout'] ?? '');
    final commentCtrl = TextEditingController(text: rule?['comment'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Address List' : 'Add Address List'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: listCtrl, decoration: const InputDecoration(labelText: 'List Name')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: timeoutCtrl, decoration: const InputDecoration(labelText: 'Timeout (optional)')),
              TextField(controller: commentCtrl, decoration: const InputDecoration(labelText: 'Comment')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (listCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty) {
                 final data = {
                   'list': listCtrl.text,
                   'address': addressCtrl.text,
                   'timeout': timeoutCtrl.text,
                   'comment': commentCtrl.text,
                 };
                 final client = ref.read(mikrotikClientProvider);
                 await client.saveFirewallRule(widget.type, data, id: id);
                 if (ctx.mounted) {
                   Navigator.pop(ctx);
                   _fetchRules();
                 }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showRuleDialog({required bool isEdit, String? id, Map<String, String>? rule}) {
    final chainCtrl = TextEditingController(text: rule?['chain'] ?? 'forward');
    final actionCtrl = TextEditingController(text: rule?['action'] ?? 'accept');
    final srcAddressCtrl = TextEditingController(text: rule?['src-address'] ?? '');
    final dstAddressCtrl = TextEditingController(text: rule?['dst-address'] ?? '');
    final protocolCtrl = TextEditingController(text: rule?['protocol'] ?? '');
    final dstPortCtrl = TextEditingController(text: rule?['dst-port'] ?? '');
    final commentCtrl = TextEditingController(text: rule?['comment'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit ${widget.type.toUpperCase()}' : 'Add ${widget.type.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: chainCtrl, decoration: const InputDecoration(labelText: 'Chain (e.g. input/forward/srcnat)')),
              TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: 'Action (e.g. accept/drop/masquerade)')),
              TextField(controller: srcAddressCtrl, decoration: const InputDecoration(labelText: 'Src Address')),
              TextField(controller: dstAddressCtrl, decoration: const InputDecoration(labelText: 'Dst Address')),
              TextField(controller: protocolCtrl, decoration: const InputDecoration(labelText: 'Protocol (e.g. tcp/udp/icmp)')),
              TextField(controller: dstPortCtrl, decoration: const InputDecoration(labelText: 'Dst Port')),
              TextField(controller: commentCtrl, decoration: const InputDecoration(labelText: 'Comment')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (chainCtrl.text.isNotEmpty && actionCtrl.text.isNotEmpty) {
                 final data = {
                   'chain': chainCtrl.text,
                   'action': actionCtrl.text,
                   'src-address': srcAddressCtrl.text,
                   'dst-address': dstAddressCtrl.text,
                   'protocol': protocolCtrl.text,
                   'dst-port': dstPortCtrl.text,
                   'comment': commentCtrl.text,
                 };
                 final client = ref.read(mikrotikClientProvider);
                 await client.saveFirewallRule(widget.type, data, id: id);
                 if (ctx.mounted) {
                   Navigator.pop(ctx);
                   _fetchRules();
                 }
              }
            },
            child: const Text('Save'),
          )
        ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRules,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _rules.length,
                itemBuilder: (ctx, idx) {
                  final rule = _rules[idx];
                  final isDisabled = rule['disabled'] == 'true';
                  final isDynamic = rule['dynamic'] == 'true';
                  
                  if (widget.type == 'address-list') {
                     return _buildAddressListCard(rule, isDisabled, isDynamic);
                  }
                  return _buildGeneralRuleCard(rule, isDisabled, isDynamic);
                },
              ),
            ),
    );
  }

  Widget _buildAddressListCard(Map<String, String> rule, bool isDisabled, bool isDynamic) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          rule['list'] ?? 'Unknown',
          style: TextStyle(
            decoration: isDisabled ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
            color: isDynamic ? Colors.grey : Colors.black
          )
        ),
        subtitle: Text('IP: ${rule["address"] ?? "-"} ${rule["timeout"] != null ? "\nTimeout: " + rule["timeout"]! : ""}\nComment: ${rule["comment"] ?? "-"}'),
        isThreeLine: true,
        trailing: _buildActions(rule, isDisabled, isDynamic),
      ),
    );
  }

  Widget _buildGeneralRuleCard(Map<String, String> rule, bool isDisabled, bool isDynamic) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
              child: Text(rule['chain'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rule['action'] ?? '',
                style: TextStyle(
                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                  color: isDynamic ? Colors.grey : Colors.black
                )
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Src: ${rule["src-address"] ?? "any"} | Dst: ${rule["dst-address"] ?? "any"}\n'
          'Proto: ${rule["protocol"] ?? "any"} ${rule["dst-port"] != null ? "Port: " + rule["dst-port"]! : ""}\n'
          'Comment: ${rule["comment"] ?? "-"}'
        ),
        isThreeLine: true,
        trailing: _buildActions(rule, isDisabled, isDynamic),
      ),
    );
  }

  Widget _buildActions(Map<String, String> rule, bool isDisabled, bool isDynamic) {
    if (isDynamic) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Text('Dynamic', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: !isDisabled,
          onChanged: (val) => _toggleEnableDisable(rule),
          activeColor: Colors.blue,
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          onPressed: () => _showFormDialog(rule: rule),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteRule(rule),
        )
      ],
    );
  }
}

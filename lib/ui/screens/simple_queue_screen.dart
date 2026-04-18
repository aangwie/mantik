import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mikrotik_provider.dart';
import 'simple_queue_traffic_screen.dart';

class SimpleQueueScreen extends ConsumerStatefulWidget {
  const SimpleQueueScreen({super.key});

  @override
  ConsumerState<SimpleQueueScreen> createState() => _SimpleQueueScreenState();
}

class _SimpleQueueScreenState extends ConsumerState<SimpleQueueScreen> {
  List<Map<String, String>> _queues = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchQueues();
  }

  Future<void> _fetchQueues() async {
    setState(() => _isLoading = true);
    final client = ref.read(mikrotikClientProvider);
    final queues = await client.getSimpleQueues();
    if (mounted) {
      setState(() {
        _queues = queues;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Queues'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchQueues),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchQueues,
              child: ListView.builder(
                itemCount: _queues.length,
                itemBuilder: (ctx, idx) {
                  final q = _queues[idx];
                  final maxLimit = q['max-limit'] ?? 'Unlimited';
                  // Simple logic to format max Limit (e.g. 1M/1M) from bites
                  // Usually Mikrotik returns max-limit as 'TX/RX' in bits, e.g., '1000000/1000000'
                  String formattedLimit = maxLimit;
                  if (maxLimit.contains('/')) {
                    final parts = maxLimit.split('/');
                    if (parts.length == 2) {
                       final upBytes = double.tryParse(parts[0]) ?? 0;
                       final downBytes = double.tryParse(parts[1]) ?? 0;
                       formattedLimit = '${_formatBytes(upBytes)} ↑ / ${_formatBytes(downBytes)} ↓';
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.speed, color: Colors.blue),
                      title: Text(q['name'] ?? 'Unknown Queue'),
                      subtitle: Text('Target: ${q["target"] ?? "-"}\nLimit: $formattedLimit'),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleQueueTrafficScreen(queue: q),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatBytes(double bytes) {
    if (bytes >= 1000000) {
      return '${(bytes / 1000000).toStringAsFixed(1)}M';
    } else if (bytes >= 1000) {
      return '${(bytes / 1000).toStringAsFixed(1)}k';
    }
    return '${bytes.toInt()} bps';
  }
}

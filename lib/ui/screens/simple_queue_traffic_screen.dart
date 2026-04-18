import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/mikrotik_provider.dart';

class SimpleQueueTrafficScreen extends ConsumerStatefulWidget {
  final Map<String, String> queue;

  const SimpleQueueTrafficScreen({super.key, required this.queue});

  @override
  ConsumerState<SimpleQueueTrafficScreen> createState() => _SimpleQueueTrafficScreenState();
}

class _SimpleQueueTrafficScreenState extends ConsumerState<SimpleQueueTrafficScreen> {
  Timer? _trafficTimer;
  final List<FlSpot> _rxSpots = [];
  final List<FlSpot> _txSpots = [];
  double _timeX = 0;
  
  String _currentTx = '0';
  String _currentRx = '0';

  @override
  void initState() {
    super.initState();
    _startTrafficMonitor();
  }

  @override
  void dispose() {
    _trafficTimer?.cancel();
    super.dispose();
  }

  void _startTrafficMonitor() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      
      final client = ref.read(mikrotikClientProvider);
      final targetQueue = widget.queue['name'] ?? '';
      if (targetQueue.isEmpty) return;

      final traffic = await client.getQueueTraffic(targetQueue);
      
      if (traffic != null && traffic['rate'] != null) {
        final rate = traffic['rate']!;
        // the property rate typically returns 'TX/RX' or 'upload/download' in bits
        final parts = rate.split('/');
        if (parts.length == 2) {
          final txBits = double.tryParse(parts[0]) ?? 0;
          final rxBits = double.tryParse(parts[1]) ?? 0;
          
          final rxMbps = rxBits / 1000000;
          final txMbps = txBits / 1000000;

          if (mounted) {
            setState(() {
              _currentTx = _formatBytes(txBits);
              _currentRx = _formatBytes(rxBits);

              _timeX += 1;
              _rxSpots.add(FlSpot(_timeX, rxMbps));
              _txSpots.add(FlSpot(_timeX, txMbps));
              
              if (_rxSpots.length > 20) {
                _rxSpots.removeAt(0);
                _txSpots.removeAt(0);
              }
            });
          }
        }
      }
    });
  }

  String _formatBytes(double bytes) {
    if (bytes >= 1000000) {
      return '${(bytes / 1000000).toStringAsFixed(1)} Mbps';
    } else if (bytes >= 1000) {
      return '${(bytes / 1000).toStringAsFixed(1)} Kbps';
    }
    return '${bytes.toInt()} bps';
  }

  @override
  Widget build(BuildContext context) {
    final maxLimit = widget.queue['max-limit'] ?? 'Unlimited';
    String formattedLimit = maxLimit;
    if (maxLimit.contains('/')) {
      final parts = maxLimit.split('/');
      if (parts.length == 2) {
         final upBytes = double.tryParse(parts[0]) ?? 0;
         final downBytes = double.tryParse(parts[1]) ?? 0;
         formattedLimit = '${_formatBytesForMax(upBytes)} ↑ / ${_formatBytesForMax(downBytes)} ↓';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.queue['name']} Traffic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                     const Text('Limitation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Text('Target: ${widget.queue["target"] ?? "-"}', style: const TextStyle(fontSize: 16)),
                     Text('Max Limit: $formattedLimit', style: const TextStyle(fontSize: 16)),
                   ],
                 )
              )
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Real-time Traffic Monitor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox('Upload (TX)', _currentTx, Colors.green),
                        _buildStatBox('Download (RX)', _currentRx, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: _rxSpots.isEmpty && _txSpots.isEmpty
                          ? const Center(child: Text('Waiting for data...'))
                          : LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _rxSpots,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _txSpots,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: true),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, color: Colors.blue, size: 12),
                        SizedBox(width: 4),
                        Text('Rx / Download'),
                        SizedBox(width: 16),
                        Icon(Icons.circle, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text('Tx / Upload'),
                      ],
                    )
                  ],
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  String _formatBytesForMax(double bytes) {
    if (bytes >= 1000000) {
      return '${(bytes / 1000000).toStringAsFixed(1)}M';
    } else if (bytes >= 1000) {
      return '${(bytes / 1000).toStringAsFixed(1)}k';
    }
    return '${bytes.toInt()} bps';
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

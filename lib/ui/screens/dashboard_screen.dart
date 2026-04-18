import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/mikrotik_provider.dart';
import 'pppoe_management_screen.dart';
import 'simple_queue_screen.dart';
import 'firewall_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _activePppoe = 0;
  int _offlinePppoe = 0;
  int _totalPppoe = 0;

  List<Map<String, String>> _interfaces = [];
  String? _selectedInterface;
  
  Timer? _trafficTimer;
  final List<FlSpot> _rxSpots = [];
  final List<FlSpot> _txSpots = [];
  double _timeX = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchSummaryData();
    await _fetchInterfaces();
  }

  @override
  void dispose() {
    _trafficTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSummaryData() async {
    final client = ref.read(mikrotikClientProvider);
    final active = await client.getPppoeActive();
    final secrets = await client.getPppoeSecrets();
    
    if (mounted) {
      setState(() {
        _activePppoe = active.length;
        int activeInSecrets = active.where((a) => secrets.any((s) => s['name'] == a['name'])).length;
        _offlinePppoe = secrets.length - activeInSecrets;
        _totalPppoe = _activePppoe + _offlinePppoe;
      });
    }
  }

  Future<void> _fetchInterfaces() async {
    final client = ref.read(mikrotikClientProvider);
    final inf = await client.getInterfaces();
    final filteredInf = inf.where((i) {
      final type = i['type']?.toLowerCase() ?? '';
      return type == 'ether' || type == 'bridge' || type == 'vlan' || type == 'wlan';
    }).toList();
    
    if (mounted && filteredInf.isNotEmpty) {
      setState(() {
        _interfaces = filteredInf;
        _selectedInterface = filteredInf.first['name'];
      });
      _startTrafficMonitor();
    }
  }

  bool _isFetchingStats = false;

  void _startTrafficMonitor() {
    _trafficTimer?.cancel();
    _rxSpots.clear();
    _txSpots.clear();
    _timeX = 0;

    _trafficTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_selectedInterface == null || !mounted || _isFetchingStats) return;
      _isFetchingStats = true;
      
      try {
        final client = ref.read(mikrotikClientProvider);
        final traffic = await client.getInterfaceTraffic(_selectedInterface!);
        
        if (traffic.isNotEmpty) {
          final rx = double.tryParse(traffic.first['rx-bits-per-second'] ?? '0') ?? 0;
          final tx = double.tryParse(traffic.first['tx-bits-per-second'] ?? '0') ?? 0;
          
          final rxMbps = rx / 1000000;
          final txMbps = tx / 1000000;

          if (mounted) {
            setState(() {
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
        
        // Refresh PPPoE Summary Real-time calculation sequentially
        await _fetchSummaryData();
      } finally {
        _isFetchingStats = false;
      }
    });
  }

  void _logout() {
    ref.read(connectionStateProvider.notifier).disconnect();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MikroTik Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchSummaryData();
            },
            tooltip: 'Refresh Summary',
          ),
        ],
      ),
      drawer: NavigationDrawer(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Management', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('PPPoE Secrets'),
            onTap: () {
              Navigator.pop(context); // Close Drawer
              _trafficTimer?.cancel();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PppoeManagementScreen())).then((_) {
                _startTrafficMonitor();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Simple Queues'),
            onTap: () {
              Navigator.pop(context);
              _trafficTimer?.cancel();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleQueueScreen())).then((_) {
                _startTrafficMonitor();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Firewall'),
            onTap: () {
              Navigator.pop(context);
              _trafficTimer?.cancel();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FirewallScreen())).then((_) {
                _startTrafficMonitor();
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PPPoE Summary
            Card(
              elevation: 4,
              child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                     const Text('PPPoE Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         _buildStatBox('Total', _totalPppoe, Colors.blue),
                         _buildStatBox('Active', _activePppoe, Colors.green),
                         _buildStatBox('Offline', _offlinePppoe, Colors.red),
                       ],
                     ),
                   ],
                 )
              )
            ),
            const SizedBox(height: 24),
            
            // Traffic Monitor
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Real-time Traffic Monitor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_interfaces.isEmpty) 
                       const Center(child: CircularProgressIndicator())
                    else
                       DropdownButton<String>(
                         isExpanded: true,
                         value: _selectedInterface,
                         items: _interfaces.map((i) => DropdownMenuItem(
                           value: i['name'],
                           child: Text(i['name'] ?? 'Unknown'),
                         )).toList(),
                         onChanged: (val) {
                           if (val != null) {
                             setState(() => _selectedInterface = val);
                             _startTrafficMonitor();
                           }
                         },
                       ),
                    const SizedBox(height: 16),
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
                        Text('Rx (Mbps)'),
                        SizedBox(width: 16),
                        Icon(Icons.circle, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text('Tx (Mbps)'),
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

  Widget _buildStatBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

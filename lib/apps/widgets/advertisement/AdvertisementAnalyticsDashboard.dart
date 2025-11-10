import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/ColorPages.dart';
import 'AdvertisementModel.dart';
import 'AdvertisementService.dart';

/// Analytics Dashboard for Advertisements
class AdvertisementAnalyticsDashboard extends StatefulWidget {
  const AdvertisementAnalyticsDashboard({super.key});

  @override
  State<AdvertisementAnalyticsDashboard> createState() => _AdvertisementAnalyticsDashboardState();
}

class _AdvertisementAnalyticsDashboardState extends State<AdvertisementAnalyticsDashboard> {
  bool _loading = true;
  List<AdvertisementModel> _advertisements = [];
  Map<String, Map<String, dynamic>> _analyticsData = {};
  
  // Summary stats
  int _totalViews = 0;
  int _totalClicks = 0;
  double _averageCTR = 0.0;
  int _activeAds = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    
    // TODO: Load from API
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for demonstration
    _advertisements = AdvertisementService.getMockAdvertisements();
    _activeAds = _advertisements.where((ad) => ad.isActive).length;
    
    // Mock analytics data
    for (var ad in _advertisements) {
      _analyticsData[ad.id] = {
        'views': (ad.priority * 100).toInt(),
        'clicks': (ad.priority * 10).toInt(),
        'ctr': (ad.priority * 10) / (ad.priority * 100),
      };
      _totalViews += (ad.priority * 100).toInt();
      _totalClicks += (ad.priority * 10).toInt();
    }
    
    _averageCTR = _totalClicks / _totalViews;
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tableau de Bord Analytique',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Summary Cards
                  _buildSummaryCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Performance Chart
                  _buildPerformanceChart(),
                  
                  const SizedBox(height: 24),
                  
                  // CTR Chart
                  _buildCTRChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Top Performing Ads
                  _buildTopPerformingAds(),
                  
                  const SizedBox(height: 24),
                  
                  // Detailed List
                  _buildDetailedList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Vues Totales',
            _totalViews.toString(),
            Iconsax.eye,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Clics Totaux',
            _totalClicks.toString(),
            Iconsax.mouse_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance des Publicités',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _advertisements.isNotEmpty 
                    ? (_advertisements.map((ad) => _analyticsData[ad.id]?['views'] ?? 0).reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _advertisements.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Ad ${value.toInt() + 1}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _advertisements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ad = entry.value;
                  final views = _analyticsData[ad.id]?['views'] ?? 0;
                  final clicks = _analyticsData[ad.id]?['clicks'] ?? 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: views.toDouble(),
                        color: Colors.blue,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: clicks.toDouble(),
                        color: Colors.green,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Vues', Colors.blue),
              const SizedBox(width: 24),
              _buildLegendItem('Clics', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTRChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taux de Clics (CTR)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _advertisements.take(5).map((ad) {
                  final ctr = _analyticsData[ad.id]?['ctr'] ?? 0.0;
                  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                  final colorIndex = _advertisements.indexOf(ad) % colors.length;
                  
                  return PieChartSectionData(
                    value: ctr * 100,
                    title: '${(ctr * 100).toStringAsFixed(1)}%',
                    color: colors[colorIndex],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTopPerformingAds() {
    final sortedAds = List<AdvertisementModel>.from(_advertisements)
      ..sort((a, b) {
        final aClicks = _analyticsData[a.id]?['clicks'] ?? 0;
        final bClicks = _analyticsData[b.id]?['clicks'] ?? 0;
        return bClicks.compareTo(aClicks);
      });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3 Publicités',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedAds.take(3).map((ad) {
            final index = sortedAds.indexOf(ad);
            final views = _analyticsData[ad.id]?['views'] ?? 0;
            final clicks = _analyticsData[ad.id]?['clicks'] ?? 0;
            final ctr = _analyticsData[ad.id]?['ctr'] ?? 0.0;
            
            return _buildTopAdItem(ad, index + 1, views, clicks, ctr);
          }),
        ],
      ),
    );
  }

  Widget _buildTopAdItem(AdvertisementModel ad, int rank, int views, int clicks, double ctr) {
    final medals = ['🥇', '🥈', '🥉'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            medals[rank - 1],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$views vues • $clicks clics • ${(ctr * 100).toStringAsFixed(1)}% CTR',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toutes les Publicités',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._advertisements.map((ad) {
            final views = _analyticsData[ad.id]?['views'] ?? 0;
            final clicks = _analyticsData[ad.id]?['clicks'] ?? 0;
            final ctr = _analyticsData[ad.id]?['ctr'] ?? 0.0;
            
            return _buildDetailedListItem(ad, views, clicks, ctr);
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedListItem(AdvertisementModel ad, int views, int clicks, double ctr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ad.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ad.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ad.isActive ? 'Actif' : 'Inactif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn('Vues', views.toString(), Iconsax.eye),
              ),
              Expanded(
                child: _buildStatColumn('Clics', clicks.toString(), Iconsax.mouse_circle),
              ),
              Expanded(
                child: _buildStatColumn('CTR', '${(ctr * 100).toStringAsFixed(1)}%', Iconsax.chart),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: ColorPages.COLOR_PRINCIPAL),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}


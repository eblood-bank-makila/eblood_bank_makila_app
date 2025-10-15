import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../config/theme/ColorPages.dart';
import '../connect/announcements/announcements_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _service = AnnouncementsService();
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchAll();
      setState(() => _all = list);
    } catch (_) {
      setState(() => _all = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _campaigns {
    return _all.where((e) {
      final type = (e['type'] ?? e['category'] ?? '').toString().toLowerCase();
      return type.contains('campaign');
    }).take(10).toList();
  }

  List<Map<String, dynamic>> get _recent {
    // if backend provides created_at, we could sort; here just take first 10
    return _all.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top header (match Banquepage style)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('app_name'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
                            Text('customer_space'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                )),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationPage(notification: []),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.notification, color: Colors.white, size: 24),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [
                              // Featured campaigns
                              if (_campaigns.isNotEmpty) ...[
                                Text('featured_campaigns'.tr, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 150,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _campaigns.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final a = _campaigns[index];
                                      final title = (a['title'] ?? a['subject'] ?? '').toString();
                                      final location = (a['location'] ?? a['place'] ?? '').toString();
                                      final priority = (a['priority'] ?? a['level'] ?? 'normal').toString();
                                      final urgent = priority.toLowerCase() == 'urgent';
                                      return Container(
                                        width: 260,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                          border: urgent ? Border.all(color: Colors.redAccent.withValues(alpha: 0.3)) : null,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    urgent ? 'urgent'.tr : 'campaign'.tr,
                                                    style: GoogleFonts.ubuntu(fontSize: 11, color: ColorPages.COLOR_PRINCIPAL, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(Icons.campaign_outlined, color: Colors.grey.shade600, size: 18),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              title.isEmpty ? 'blood_donation_campaign'.tr : title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade600),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    location.isEmpty ? 'location_unspecified'.tr : location,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade700),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Recent announcements
                              Text('recent_announcements'.tr, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              if (_recent.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text('no_announcements_now'.tr, style: GoogleFonts.ubuntu(color: Colors.grey.shade700)),
                                )
                              else
                                ..._recent.map((a) {
                                  final title = (a['title'] ?? a['subject'] ?? '').toString();
                                  final type = (a['type'] ?? a['category'] ?? 'News').toString();
                                  final location = (a['location'] ?? a['place'] ?? '').toString();
                                  final priority = (a['priority'] ?? a['level'] ?? 'normal').toString();
                                  final urgent = priority.toLowerCase() == 'urgent';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: urgent
                                                ? Colors.redAccent.withValues(alpha: 0.1)
                                                : ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            urgent ? Icons.priority_high : Icons.campaign_outlined,
                                            color: urgent ? Colors.redAccent : ColorPages.COLOR_PRINCIPAL,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title.isEmpty ? 'announcement'.tr : title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(type, style: GoogleFonts.ubuntu(fontSize: 11, color: Colors.grey.shade800)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (location.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                                                        const SizedBox(width: 4),
                                                        Text(location, style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade700)),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

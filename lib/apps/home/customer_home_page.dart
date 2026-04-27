import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../config/theme/ColorPages.dart';
import '../connect/announcements/announcements_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';

import 'package:get_storage/get_storage.dart';
import '../../core/rbac/providers/rbac_provider.dart';
import '../../stock_management/ui/pages/recherchePoche/RecherchePochePage.dart';
// Removed from quick actions per requirement
// import '../../orders/ui/pages/blood_request/BloodRequestPage.dart';
import '../../delivery/ui/pages/DeliveryPersonHomePage.dart';
import '../widgets/advertisement/AdvertisementCarousel.dart';
import 'nearby_blood_banks_page.dart';
import 'top_donors_page.dart';
import 'my_blood_donor_profile_page.dart';
import 'donation_history_page.dart';
import 'volunteer_donor_dashboard_page.dart';
import '../volunteer/benevol_donor_landing_page.dart';
import '../donor/donor_landing_page.dart';

import '../ins/ins_landing_page.dart';

import '../services/AuthService.dart';
import '../ins/ins_request_details_page.dart';


class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> with WidgetsBindingObserver {
  final _service = AnnouncementsService();
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  final _box = GetStorage();
  bool _isDonor = false;
  // _isDelivery removed in Phase 5 — the delivery dashboard card is now
  // gated purely by the cust_home_delivery_dashboard RBAC flag, which
  // requires the MOBILE_APP_DELIVERY_PERSON_PROFILE extra profile.
  bool _isVolunteerDonor = false;
  String _firstName = '';
  final _auth = AuthService();
  bool _hasInsRequest = false;
  Map<String, dynamic>? _insRequestData;

  /// RBAC helper — checks whether a given sub_menu flag is present in the
  /// loaded applications tree. Mirrors the pattern from BloodBankHomePage.
  bool _hasFlag(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileFlags();
    _subscribeToProfileUpdates();
    _checkInsRequest();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 CustomerHome - app resumed, refreshing profile flags');
      _loadProfileFlags();
    }
  }

  void _subscribeToProfileUpdates() {
    final handler = (dynamic value) {
      debugPrint('📢 CustomerHome - storage update detected for key, value: $value');
      _loadProfileFlags();
    };
    _box.listenKey('user_profiles', handler);
    _box.listenKey('user_profils', handler);
    _box.listenKey('user_data', handler);
    debugPrint('✅ CustomerHome - subscribed to profile updates');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchAll().timeout(
        const Duration(seconds: 10),
        onTimeout: () => <Map<String, dynamic>>[],
      );
      setState(() => _all = list);
      // Also refresh profile flags when user pulls to refresh
      _loadProfileFlags();
      await _checkInsRequest();
    } catch (_) {
      setState(() => _all = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadProfileFlags() {
    bool newIsDonor = _isDonor;
    bool newIsVolunteerDonor = _isVolunteerDonor;
    String newFirstName = _firstName;

    try {
      final profiles = _box.read('user_profiles') ?? _box.read('user_profils') ?? [];
      debugPrint('🔍 CustomerHome _loadProfileFlags - profiles: $profiles');

      if (profiles is List) {
        // Extract ALL profiles regardless of 'enabled' status
        // The 'enabled' field will be used later to disable actions, not to hide profiles
        final allProfiles = profiles.whereType<Map>().toList();
        debugPrint('🔍 CustomerHome - all profiles: $allProfiles');

        final flags = allProfiles
            .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toSet();
        debugPrint('🔍 CustomerHome - extracted flags: $flags');

        newIsDonor = flags.contains('mobile_app_blood_donor_profil');
        newIsVolunteerDonor = flags.contains('mobile_app_volonteer_blood_donor_profil');

        debugPrint('🔍 CustomerHome - newIsDonor: $newIsDonor, newIsVolunteerDonor: $newIsVolunteerDonor');
      }

      final user = _box.read('user_data');
      if (user is Map) {
        newFirstName = (user['first_name'] ?? user['uPrenom'] ?? user['username'] ?? '').toString();
      }
    } catch (e) {
      debugPrint('⚠️ CustomerHome _loadProfileFlags error: $e');
    }

    if (!mounted) {
      _isDonor = newIsDonor;
      _isVolunteerDonor = newIsVolunteerDonor;
      _firstName = newFirstName;
      return;
    }

    debugPrint('🔍 CustomerHome - comparing: old isDonor=$_isDonor vs new=$newIsDonor, old isVolunteerDonor=$_isVolunteerDonor vs new=$newIsVolunteerDonor');
    if (newIsDonor != _isDonor || newIsVolunteerDonor != _isVolunteerDonor || newFirstName != _firstName) {
      debugPrint('✅ CustomerHome - updating state: isDonor=$newIsDonor, isVolunteerDonor=$newIsVolunteerDonor');
      setState(() {
        _isDonor = newIsDonor;
        _isVolunteerDonor = newIsVolunteerDonor;
        _firstName = newFirstName;
      });
    } else {
      debugPrint('ℹ️ CustomerHome - no state change needed');
    }
  }
  Future<void> _checkInsRequest() async {
    try {
      final resp = await _auth.getMyInsRequest();
      if (!mounted) return;
      if (resp.success && resp.data is Map) {
        setState(() {
          _hasInsRequest = true;
          _insRequestData = Map<String, dynamic>.from(resp.data as Map);
        });
      } else {
        final code = resp.statusCode ?? 0;
        if (code == 404) {
          if (_hasInsRequest || _insRequestData != null) {
            setState(() {
              _hasInsRequest = false;
              _insRequestData = null;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ _checkInsRequest error: $e');
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

  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Row with Logo and Notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Welcome Text
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
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
                      Text(
                        'E-Blood Bank',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      Text(
                        'Trouvez du sang rapidement',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notification Button
              Container(
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(
                              notification: [],
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Iconsax.notification,
                        color: ColorPages.COLOR_PRINCIPAL,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Modern Search Bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Recherchepage(
                    query: '',
                    isModal: true,
                  ),
                ),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Icon(
                    Iconsax.search_normal,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Rechercher une poche... ex. A+',
                      style: GoogleFonts.ubuntu(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Iconsax.search_normal,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style to dark (black icons/text)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade100,
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context),

              // Content container - no rounded corners, no shadow
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [
                              // Advertisement Carousel (top of content)
                              const AdvertisementCarousel(
                                targetAudience: 'all',
                                height: 180,
                                autoPlay: true,
                                autoPlayDuration: Duration(seconds: 10),
                                showIndicators: true,
                                useMockData: false,
                              ),
                              const SizedBox(height: 24),

                              const SizedBox(height: 8),
                              if (_firstName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${'welcome'.tr}, \u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E\u200E$_firstName',
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: ColorPages.COLOR_PRINCIPAL,
                                    ),
                                  ),
                                ),
                              // Primary CTA buttons on top of quick actions
                              const SizedBox(height: 18),
                              _buildPrimaryCTASection(context),
                              const SizedBox(height: 28),
                              Text('quick_actions'.tr, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              _buildQuickActionsSection(context),
                              const SizedBox(height: 16),
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
                                }),
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

  Widget _buildPrimaryCTASection(BuildContext context) {
    // RBAC gates for primary CTAs — each button is locked when its
    // corresponding sub_menu flag is missing from the loaded apps.
    final canVolunteer  = _hasFlag('flutter_apps_eblood_bank_cust_home_volunteer');
    final canInsRequest = _hasFlag('flutter_apps_eblood_bank_cust_home_ins_request');

    // Show volunteer donor dashboard for existing volunteer donors
    if (_isVolunteerDonor) {
      return Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(
              title: 'my_volunteer_dashboard'.tr,
              icon: Icons.volunteer_activism,
              color: Colors.green.shade600,
              locked: !canVolunteer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VolunteerDonorDashboardPage()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPrimaryButton(
              title: _hasInsRequest ? 'view_my_ins_request'.tr : 'request_your_ins'.tr,
              icon: Icons.badge_outlined,
              color: Colors.indigo,
              locked: !canInsRequest,
              onTap: () {
                if (_hasInsRequest && _insRequestData != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InsRequestDetailsPage(data: _insRequestData!)),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InsLandingPage()),
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    // Show both buttons for non-volunteer donors
    return Row(
      children: [
        Expanded(
          child: _buildPrimaryButton(
            title: 'become_benevol_donor'.tr,
            icon: Icons.volunteer_activism,
            color: ColorPages.COLOR_PRINCIPAL,
            locked: !canVolunteer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BenevolDonorLandingPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPrimaryButton(
            title: _hasInsRequest ? 'view_my_ins_request'.tr : 'request_your_ins'.tr,
            icon: Icons.badge_outlined,
            color: Colors.indigo,
            locked: !canInsRequest,
            onTap: () {
              if (_hasInsRequest && _insRequestData != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InsRequestDetailsPage(data: _insRequestData!)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InsLandingPage()),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    // Mirror BloodBankHomePage's locked-card pattern: disable tap, dim
    // the background colour, and wrap the whole button in Opacity.
    final effectiveColor = locked ? Colors.grey.shade400 : color;
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ubuntu(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    // RBAC gates — mirror the BloodBankHomePage pattern. Each card is locked
    // when its corresponding sub_menu flag is missing from the loaded apps.
    // Note: Phase 2 keeps the existing GetStorage-based _isDonor visibility
    // gates in place; the delivery card has been migrated to pure RBAC in
    // Phase 5 (the cust_home_delivery_dashboard flag is only granted to
    // users with the MOBILE_APP_DELIVERY_PERSON_PROFILE extra profile).
    final canBecomeDonor    = _hasFlag('flutter_apps_eblood_bank_cust_home_become_donor');
    final canTopDonors      = _hasFlag('flutter_apps_eblood_bank_cust_home_top_donors');
    final canFindBlood      = _hasFlag('flutter_apps_eblood_bank_cust_home_find_blood');
    final canNearbyBanks    = _hasFlag('flutter_apps_eblood_bank_cust_home_nearby_banks');
    final canDonorProfile   = _hasFlag('flutter_apps_eblood_bank_cust_home_donor_profile');
    final canDonationHist   = _hasFlag('flutter_apps_eblood_bank_cust_home_donation_history');
    final canDeliveryDash   = _hasFlag('flutter_apps_eblood_bank_cust_home_delivery_dashboard');

    final cards = <Widget>[];

    // Become Donor (only if user is not a donor)
    if (!_isDonor) {
      cards.add(_buildActionCard(
        title: 'become_donor'.tr,
        subtitle: 'blood_donor'.tr,
        icon: Iconsax.heart_add,
        color: Colors.redAccent,
        locked: !canBecomeDonor,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonorLandingPage()),
        ),
      ));
    }

    // Top Donors
    cards.add(_buildActionCard(
      title: 'top_donors'.tr,
      subtitle: 'donors'.tr,
      icon: Iconsax.crown,
      color: Colors.orange,
      locked: !canTopDonors,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomerTopDonorsPage()),
      ),
    ));

    // Delivery Dashboard — pure RBAC gating: the card is only added when
    // the user has the cust_home_delivery_dashboard sub_menu flag, which
    // requires the MOBILE_APP_DELIVERY_PERSON_PROFILE extra profile.
    if (canDeliveryDash) {
      cards.add(_buildActionCard(
        title: 'delivery_dashboard'.tr,
        subtitle: 'dashboard'.tr,
        icon: Iconsax.truck,
        color: Colors.teal,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DeliveryPersonHomePage(),
          ),
        ),
      ));
    }

    // Find Blood
    cards.add(_buildActionCard(
      title: 'find_blood'.tr,
      subtitle: 'search'.tr,
      icon: Iconsax.search_normal_1,
      color: Colors.indigo,
      locked: !canFindBlood,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Recherchepage(query: '', isModal: true),
        ),
      ),
    ));


    // Nearby Blood Banks (customer-specific, no cart features)
    cards.add(_buildActionCard(
      title: 'nearby_blood_banks'.tr,
      subtitle: 'medical_network'.tr,
      icon: Iconsax.hospital,
      color: Colors.green,
      locked: !canNearbyBanks,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomerNearbyBloodBanksPage()),
      ),
    ));

    // Donor-only actions
    if (_isDonor) {
      cards.add(_buildActionCard(
        title: 'my_blood_donor_profile'.tr,
        subtitle: 'blood_donor'.tr,
        icon: Iconsax.profile_circle,
        color: Colors.redAccent,
        locked: !canDonorProfile,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyBloodDonorProfilePage()),
        ),
      ));
      cards.add(_buildActionCard(
        title: 'donation_history'.tr,
        subtitle: 'my_donations'.tr,
        icon: Iconsax.activity,
        color: Colors.blueGrey,
        locked: !canDonationHist,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonationHistoryPage()),
        ),
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: cards,
    );
  }

  Widget _buildActionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    // Mirror BloodBankHomePage's locked-card pattern: disable tap, dim
    // the icon colour, and wrap the whole card in Opacity.
    final effectiveColor = locked ? Colors.grey.shade400 : color;
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

}

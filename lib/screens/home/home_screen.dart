import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../services/auth_service.dart';
import '../../models/blood_request_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/blood_request_card.dart';
import '../../widgets/section_header.dart';
import '../blood_request/my_requests_screen.dart';
import '../blood_request/my_donations_screen.dart';



import '../../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const HomeScreen({super.key, this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      context.read<BloodRequestProvider>().init(user?.id);
      
      if (user != null) {
        context.read<NotificationProvider>().listenToNotifications(user.id);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final requestProvider = context.watch<BloodRequestProvider>();

    final requests = requestProvider.nearbyRequests;
    final myRequests = requestProvider.myRequests;
    final myRequestsCount = myRequests.length;
    final myDonationsCount = requestProvider.myDonations.length;
    final latestRequest = myRequests.isNotEmpty ? myRequests.first : null;


    return Scaffold(
      body: Column(
        children: [
          _header(context, user, latestRequest),
          Expanded(
            child: requestProvider.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    children: [
                      // 📊 QUICK STATS / INFO
                      _quickStatsRow(myDonationsCount, myRequestsCount),
                      const SizedBox(height: 32),


                      SectionHeader(
                        title: 'Emergency Requests',
                        actionLabel: 'View All',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ViewAllRequestsScreen()),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// EMPTY STATE
                      if (requests.isEmpty)
                        _emptyState()
                      else
                        ...requests.take(3).map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BloodRequestCard(
                              request: r,
                              onRespond: (user != null && r.requestedBy == user.id)
                                ? null 
                                : () => _onRespond(context, r),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                      _donorBanner(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _quickStatsRow(int myDonationsCount, int myRequestsCount) {
    return Row(
      children: [
        _statCard('Donations', '$myDonationsCount', Icons.volunteer_activism_outlined, AppTheme.primaryRed,

          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDonationsScreen()))),
        const SizedBox(width: 16),
        _statCard('My Requests', '$myRequestsCount', Icons.emergency_share_outlined, AppTheme.blue, 
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen()))),
      ],
    );
  }


  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gray100),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.gray900)),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gray100),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.gray200, size: 64),
          const SizedBox(height: 16),
          const Text(
            'All Safe Nearby',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800),
          ),
          const SizedBox(height: 4),
          const Text(
            'No emergency requests in your 50km radius.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.gray400),
          ),
        ],
      ),
    );
  }

  Widget _donorBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryRed, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Save a Life Today', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Your blood donation can save up to 3 lives.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryRed,
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Learn More', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Future<void> _onRespond(BuildContext context, BloodRequestModel request) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
    );

    final authService = AuthService();
    final solicitor = await authService.getUserById(request.requestedBy);
    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (solicitor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch solicitor details'), backgroundColor: AppTheme.primaryRed));
      return;
    }

    final currentUser = context.read<AuthProvider>().user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray200, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Solicitor Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.gray900)),
              const SizedBox(height: 20),
              _detailRow(Icons.person_outlined, solicitor.name, 'Requester Name'),
              _detailRow(Icons.phone_outlined, solicitor.phone, 'Contact Number'),
              _detailRow(Icons.location_on_outlined, solicitor.location, 'Location'),
              const SizedBox(height: 12),
              
              // Distance & Maps Integration
              FutureBuilder(
                future: LocationService().getCurrentPosition(),
                builder: (context, snapshot) {
                  final donorPos = snapshot.hasData ? snapshot.data : null;
                  final double? destLat = request.latitude ?? solicitor.latitude;
                  final double? destLng = request.longitude ?? solicitor.longitude;

                  if (donorPos != null && destLat != null && destLng != null) {
                    final dist = LocationService().distanceBetween(
                      donorPos.latitude,
                      donorPos.longitude,
                      destLat,
                      destLng,
                    );

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${dist.toStringAsFixed(1)} KM AWAY FROM YOU',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryRed,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final url = 'https://www.google.com/maps/dir/?api=1&origin=${donorPos.latitude},${donorPos.longitude}&destination=$destLat,$destLng&travelmode=driving';
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.directions_rounded, size: 18),
                                label: const Text('Navigate in Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Always show directions button using address fallback
                    return ElevatedButton.icon(
                      onPressed: () async {
                        final encodedAddress = Uri.encodeComponent(solicitor.location);
                        final url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Get Directions to Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primaryRed,
                        side: BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchCaller(solicitor.phone, request, currentUser?.name ?? 'A donor', currentUser?.id ?? ''),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchMessenger(solicitor.phone, request, currentUser?.name ?? 'A donor', currentUser?.id ?? ''),
                      icon: const Icon(Icons.message_rounded, size: 18),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppTheme.gray200),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.gray600)),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchCaller(String phone, BloodRequestModel request, String donorName, String donorId) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      if (!mounted) return;
      context.read<BloodRequestProvider>().notifyRequesterOfInteraction(request, donorName, 'call', donorId);
      await launchUrl(url);
    }
  }

  Future<void> _launchMessenger(String phone, BloodRequestModel request, String donorName, String donorId) async {
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      if (!mounted) return;
      context.read<BloodRequestProvider>().notifyRequesterOfInteraction(request, donorName, 'message', donorId);
      await launchUrl(url);
    }
  }





  Widget _detailRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.gray50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryRed, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= HEADER =================
  Widget _header(BuildContext context, UserModel? user, BloodRequestModel? latestRequest) {
    final name = user?.name ?? 'User';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      '$name 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: widget.onMenuTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _latestRequestTicker(latestRequest),
        ],
      ),
    );
  }

  Widget _latestRequestTicker(BloodRequestModel? request) {
    if (request == null) {
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.4), size: 16),
            const SizedBox(width: 12),
            Text(
              'No active requests found',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return _AnimatedRequestTicker(request: request);
  }
}

class _AnimatedRequestTicker extends StatefulWidget {
  final BloodRequestModel request;
  const _AnimatedRequestTicker({required this.request});

  @override
  State<_AnimatedRequestTicker> createState() => _AnimatedRequestTickerState();
}

class _AnimatedRequestTickerState extends State<_AnimatedRequestTicker> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedRequestTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _resetAnimation();
    }
  }

  void _initAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startScrolling();
    });
  }

  void _resetAnimation() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    // Restart logic is handled by the loop checking mounted/hasClients
  }

  void _startScrolling() async {
    if (_isScrolling) return;
    _isScrolling = true;

    while (mounted) {
      try {
        if (!_scrollController.hasClients) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        // Scroll to end
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: (maxScroll * 45).toInt()),
          curve: Curves.linear,
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;

        // Reset to start
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        // Handle unexpected controller errors (e.g. during rebuild)
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    _isScrolling = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dateStr;
    try {
      dateStr = DateFormat('MMM dd, hh:mm a').format(widget.request.createdAt);
    } catch (_) {
      dateStr = 'Recently';
    }

    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.2), blurRadius: 4),
              ],
            ),
            child: const Text(
              'LATEST',
              style: TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    '${widget.request.patientName} (${widget.request.bloodGroup})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '• $dateStr',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '• ${widget.request.hospitalName}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 60), // Space for loop
                ],
              ),
            ),
          ),
          Icon(Icons.bolt_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}

/// ================= NEW SCREEN: VIEW ALL =================
class ViewAllRequestsScreen extends StatelessWidget {
  const ViewAllRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<BloodRequestProvider>();
    final requests = requestProvider.nearbyRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Requests'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BloodRequestCard(
              request: r,
              onRespond: (Provider.of<AuthProvider>(context, listen: false).user?.id != null && 
                          r.requestedBy == Provider.of<AuthProvider>(context, listen: false).user?.id)
                ? null
                : () => _handleRespond(context, r),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRespond(BuildContext context, BloodRequestModel request) async {
    final authService = AuthService();
    final solicitor = await authService.getUserById(request.requestedBy);
    if (solicitor == null || !context.mounted) return;

    final currentUser = context.read<AuthProvider>().user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Contact ${solicitor.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.gray900)),
            const SizedBox(height: 8),
            Text('Request for ${request.bloodGroup} at ${request.hospitalName}', style: const TextStyle(fontSize: 14, color: AppTheme.gray600)),
            const SizedBox(height: 16),
            
            // Distance & Maps Integration
            FutureBuilder(
              future: LocationService().getCurrentPosition(),
              builder: (context, snapshot) {
                final donorPos = snapshot.hasData ? snapshot.data : null;
                final double? destLat = request.latitude ?? solicitor.latitude;
                final double? destLng = request.longitude ?? solicitor.longitude;

                if (donorPos != null && destLat != null && destLng != null) {
                  final dist = LocationService().distanceBetween(
                    donorPos.latitude,
                    donorPos.longitude,
                    destLat,
                    destLng,
                  );

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${dist.toStringAsFixed(1)} KM AWAY FROM YOU',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryRed,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = 'https://www.google.com/maps/dir/?api=1&origin=${donorPos.latitude},${donorPos.longitude}&destination=$destLat,$destLng&travelmode=driving';
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.directions_rounded, size: 16),
                              label: const Text('Navigate in Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: const Size(double.infinity, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final encodedAddress = Uri.encodeComponent(solicitor.location);
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.directions_outlined, size: 16),
                        label: const Text('Get Directions to Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryRed,
                          side: BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('tel:${solicitor.phone}');
                      if (await canLaunchUrl(url)) {
                        if (!context.mounted) return;
                        context.read<BloodRequestProvider>().notifyRequesterOfInteraction(request, currentUser?.name ?? 'Donor', 'call', currentUser?.id ?? '');
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('sms:${solicitor.phone}');
                      if (await canLaunchUrl(url)) {
                        if (!context.mounted) return;
                        context.read<BloodRequestProvider>().notifyRequesterOfInteraction(request, currentUser?.name ?? 'Donor', 'message', currentUser?.id ?? '');
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.message_rounded),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

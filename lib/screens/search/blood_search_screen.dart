import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/donor_card.dart';

class BloodSearchScreen extends StatefulWidget {
  const BloodSearchScreen({super.key});
  @override
  State<BloodSearchScreen> createState() => _BloodSearchScreenState();
}

class _BloodSearchScreenState extends State<BloodSearchScreen> {
  String? _selectedGroup;
  String _filter = 'All';
  final List<String> _filters = ['All', 'Donors', 'Hospitals', 'Blood Banks'];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searched = false;
  String _sortBy = 'name'; // name | rating | availability | distance
  bool _showAvailableOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final city = _searchCtrl.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a city or location'),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<BloodRequestProvider>().loadBloodStock(city);
    await context.read<BloodRequestProvider>().searchDonors(null, city);
    setState(() {
      _searched = true;
      _selectedGroup = null;
    });
  }

  Future<void> _selectBloodGroup(String g) async {
    final city = _searchCtrl.text.trim();
    setState(() => _selectedGroup = g);
    await context.read<BloodRequestProvider>().searchDonors(g, city);
    if (mounted) setState(() {});
  }

  void _applySort(String sortType) {
    final provider = context.read<BloodRequestProvider>();
    setState(() => _sortBy = sortType);
    switch (sortType) {
      case 'name':
        provider.sortDonorsByName();
        break;
      case 'rating':
        provider.sortDonorsByRating();
        break;
      case 'availability':
        provider.sortDonorsByAvailability();
        break;
      case 'distance':
        provider.sortDonorsByDistance();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<BloodRequestProvider>();

    final allDonors = requestProvider.nearbyDonors;
    final donors = allDonors.where((DonorModel d) {
      if (_showAvailableOnly && !d.isAvailable) return false;
      if (_filter == 'Donors') return d.type == 'donor';
      if (_filter == 'Hospitals') return d.type == 'hospital';
      if (_filter == 'Blood Banks') return d.type == 'blood_bank';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                _searchBar(),
                const SizedBox(height: 24),
                _filterRow(donors.length),
                const SizedBox(height: 24),

                if (!_searched)
                  _emptySearchState()
                else ...[
                  _bloodGroupSelector(),
                  const SizedBox(height: 32),
                  
                  if (_selectedGroup != null) ...[
                    _sourceChart(),
                    const SizedBox(height: 32),
                  ],

                  _resultsSection(requestProvider, donors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(BloodRequestProvider provider, List<DonorModel> donors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${donors.length} Results Found',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.gray900),
            ),
            _sortButton(),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.loading && donors.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryRed)))
        else if (donors.isEmpty)
          _noResultsState()
        else
          ...donors.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DonorCard(
                  donor: e.value,
                  isClosest: e.key == 0,
                  onContact: () => _showContactSheet(context, e.value),
                ),
              )),
      ],
    );
  }

  Widget _sortButton() {
    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.lightRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded, color: AppTheme.primaryRed, size: 16),
            const SizedBox(width: 4),
            Text(
              _sortBy.substring(0, 1).toUpperCase() + _sortBy.substring(1),
              style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySearchState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.lightRed, shape: BoxShape.circle),
            child: const Icon(Icons.location_searching_rounded, color: AppTheme.primaryRed, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Search for Blood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          const SizedBox(height: 8),
          const Text(
            'Enter a city or area above to find registered donors and available blood stock near you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.gray600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _noResultsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded, color: AppTheme.gray200, size: 64),
          const SizedBox(height: 16),
          const Text('No matching results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
          const SizedBox(height: 4),
          const Text('Try a different city or blood group', style: TextStyle(fontSize: 13, color: AppTheme.gray400)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
          const Text(
            'Blood Search',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Find donors and hospitals in real-time',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _doSearch(),
        decoration: InputDecoration(
          hintText: 'Enter city or area...',
          prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryRed),
          suffixIcon: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            ),
            onPressed: _doSearch,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _filterRow(int count) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final isSelected = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.primaryRed : AppTheme.gray100),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.gray600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Available Only", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.gray700)),
            Switch(
              value: _showAvailableOnly,
              activeThumbColor: AppTheme.green,
              onChanged: (val) => setState(() => _showAvailableOnly = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bloodGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Blood Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.bloodGroups.map((g) {
            final isSelected = _selectedGroup == g;
            return GestureDetector(
              onTap: () => _selectBloodGroup(g),
              child: Container(
                width: 70,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRed : AppTheme.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.primaryRed : AppTheme.gray100),
                ),
                child: Center(
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sourceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          const SizedBox(height: 20),
          _chartBar('Hospitals', 0.7, AppTheme.blue),
          const SizedBox(height: 12),
          _chartBar('Blood Banks', 0.4, AppTheme.orange),
          const SizedBox(height: 12),
          _chartBar('Private Donors', 0.9, AppTheme.green),
        ],
      ),
    );
  }

  Widget _chartBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
            Text('${(percent * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: AppTheme.gray50, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Sort Results By', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.gray900)),
            const SizedBox(height: 24),
            _sortOption(ctx, 'name', Icons.sort_by_alpha_rounded, 'Name'),
            _sortOption(ctx, 'rating', Icons.star_outline_rounded, 'Rating'),
            _sortOption(ctx, 'availability', Icons.check_circle_outline_rounded, 'Availability'),
            _sortOption(ctx, 'distance', Icons.map_outlined, 'Distance'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(BuildContext ctx, String type, IconData icon, String label) {
    final isActive = _sortBy == type;
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _applySort(type);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightRed : AppTheme.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppTheme.primaryRed : AppTheme.gray100),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppTheme.primaryRed : AppTheme.gray400, size: 20),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isActive ? AppTheme.primaryRed : AppTheme.gray800)),
            const Spacer(),
            if (isActive) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryRed, size: 20),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context, DonorModel donor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: AppTheme.lightRed, borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(donor.initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryRed))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.gray900)),
                      Text('${donor.bloodGroup} · ${donor.location}', style: const TextStyle(fontSize: 14, color: AppTheme.gray600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final user = context.read<AuthProvider>().user;
                      context.read<BloodRequestProvider>().notifyDonorOfInteraction(donor, user?.name ?? 'A requester', 'call', user?.id ?? '');
                      _launch('tel:${donor.phone}');
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Call Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final user = context.read<AuthProvider>().user;
                      context.read<BloodRequestProvider>().notifyDonorOfInteraction(donor, user?.name ?? 'A requester', 'message', user?.id ?? '');
                      _launch('sms:${donor.phone}');
                    },
                    icon: const Icon(Icons.message_rounded),
                    label: const Text('Message'),
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

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/resident.dart';
import 'resident_detail_screen.dart';

/// Full-page browseable directory of all residents across every NGO.
/// Donors can filter by need, urgency, and search by name / care home.
class ResidentBrowseScreen extends StatefulWidget {
  const ResidentBrowseScreen({super.key});

  @override
  State<ResidentBrowseScreen> createState() => _ResidentBrowseScreenState();
}

class _ResidentBrowseScreenState extends State<ResidentBrowseScreen> {
  String _search = '';
  String _needFilter  = 'All';
  String _urgencyFilter = 'All';

  static const _needs = [
    'All', 'medical', 'food', 'clothing', 'companionship',
    'education', 'physiotherapy', 'shelter', 'mental health',
  ];
  static const _urgencies = ['All', 'normal', 'urgent', 'critical'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.donorBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Find & Help',
                          style: AidTextStyles.displaySm
                              .copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('Browse residents who need you',
                          style: AidTextStyles.bodyMd
                              .copyWith(color: AidColors.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AidColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or care home…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AidColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AidColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Need filter chips ──────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _needs.length,
                separatorBuilder: (_, __) => const Gap(6),
                itemBuilder: (_, i) {
                  final n = _needs[i];
                  final selected = _needFilter == n;
                  return GestureDetector(
                    onTap: () => setState(() => _needFilter = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AidColors.donorAccent
                            : AidColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AidColors.donorAccent
                              : AidColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        n[0].toUpperCase() + n.substring(1),
                        style: TextStyle(
                          color: selected ? Colors.white : AidColors.textMuted,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Gap(8),

            // ── Urgency filter chips ───────────────────────────────────────────
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _urgencies.length,
                separatorBuilder: (_, __) => const Gap(6),
                itemBuilder: (_, i) {
                  final u = _urgencies[i];
                  final selected = _urgencyFilter == u;
                  final color = u == 'critical'
                      ? const Color(0xFFE8514A)
                      : u == 'urgent'
                          ? const Color(0xFFF0A500)
                          : AidColors.ngoAccent;
                  return GestureDetector(
                    onTap: () => setState(() => _urgencyFilter = u),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : AidColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        u[0].toUpperCase() + u.substring(1),
                        style: TextStyle(
                          color: selected ? color : AidColors.textMuted,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Gap(12),

            // ── Grid ───────────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('residents')
                    .where('isActive', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AidColors.donorAccent));
                  }

                  var residents = (snap.data?.docs ?? [])
                      .map((d) => Resident.fromDoc(d))
                      .toList();

                  // Apply filters
                  if (_needFilter != 'All') {
                    residents = residents
                        .where((r) => r.needs.contains(_needFilter))
                        .toList();
                  }
                  if (_urgencyFilter != 'All') {
                    residents = residents
                        .where((r) => r.urgency == _urgencyFilter)
                        .toList();
                  }
                  if (_search.isNotEmpty) {
                    residents = residents
                        .where((r) =>
                            r.name.toLowerCase().contains(_search) ||
                            r.careHomeName.toLowerCase().contains(_search) ||
                            r.careHomeLocation.toLowerCase().contains(_search))
                        .toList();
                  }

                  if (residents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍',
                              style: TextStyle(fontSize: 48)),
                          const Gap(12),
                          Text('No residents found',
                              style: AidTextStyles.headingMd),
                          const Gap(6),
                          Text(
                            'Try changing your filters',
                            style: AidTextStyles.bodyMd
                                .copyWith(color: AidColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: residents.length,
                    itemBuilder: (_, i) =>
                        _BrowseCard(resident: residents[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Browse Card ───────────────────────────────────────────────────────────────

class _BrowseCard extends StatelessWidget {
  final Resident resident;
  const _BrowseCard({required this.resident});

  Color get _urgencyColor =>
      Color(Resident.urgencyColors[resident.urgency] ?? 0xFF2B8CE6);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResidentDetailScreen(resident: resident)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _urgencyColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: resident.photoUrl.isNotEmpty
                      ? Image.network(
                          resident.photoUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Urgency badge
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _urgencyColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      resident.urgency.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Monthly progress
                if (resident.monthlyTarget > 0)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: LinearProgressIndicator(
                      value: (resident.monthlyRaised / resident.monthlyTarget)
                          .clamp(0.0, 1.0),
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.4),
                      valueColor:
                          AlwaysStoppedAnimation(_urgencyColor),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),

            // Info
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident.name,
                    style: AidTextStyles.headingSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${resident.age} yrs · ${resident.careHomeName}',
                    style: AidTextStyles.labelSm
                        .copyWith(color: AidColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: resident.needs.take(2).map((n) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AidColors.donorAccent
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(n,
                          style: TextStyle(
                              color: AidColors.donorAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 130,
        width: double.infinity,
        color: AidColors.donorAccent.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            resident.name.isNotEmpty
                ? resident.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: AidColors.donorAccent,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

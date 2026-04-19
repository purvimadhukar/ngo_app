import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';

// ─── Public resource data model ───────────────────────────────────────────────

class WelfareResource {
  final String name;
  final String description;
  final String? phone;
  final String location;
  const WelfareResource(this.name, this.description, this.phone, this.location);
}

class WelfareCategory {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<WelfareResource> items;
  const WelfareCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
  });
}

// ─── Master resource list (shared across NGO + Donor dashboards) ──────────────

const kWelfareCategories = <WelfareCategory>[
  WelfareCategory(
    icon: Icons.local_hospital_rounded,
    title: 'Government Hospitals',
    subtitle: 'Free & subsidized treatment centers',
    color: Color(0xFFE91E63),
    items: [
      WelfareResource('AIIMS', 'All India Institute of Medical Sciences — free treatment for all citizens',
          '011-26588500', 'Delhi & multiple cities'),
      WelfareResource('NIMHANS', 'National Institute of Mental Health & Neurosciences — psychiatric care',
          '080-46110007', 'Bangalore'),
      WelfareResource('Ram Manohar Lohia Hospital', 'Government hospital — free OPD & emergency services',
          '011-23365525', 'New Delhi'),
      WelfareResource('ESI Hospitals', 'Employee State Insurance — free treatment for registered members',
          '1800-11-3839', 'Pan India (300+ hospitals)'),
    ],
  ),
  WelfareCategory(
    icon: Icons.water_drop_rounded,
    title: 'Blood Banks',
    subtitle: 'Voluntary donation & emergency requests',
    color: Color(0xFFE8514A),
    items: [
      WelfareResource('Indian Red Cross Society', 'Largest blood bank network — emergency blood requests 24/7',
          '1800-180-7999', 'Pan India (Toll Free)'),
      WelfareResource('eBloodServices', 'Online blood request — connects 2,000+ banks nationwide',
          null, 'ebloodservices.org'),
      WelfareResource('Sankalp India Foundation', 'Blood drives, thalassemia support & patient coordination',
          '080-23568451', 'Bangalore & expanding'),
      WelfareResource('National Blood Transfusion Council', 'Government blood coordination helpline',
          '011-23062300', 'New Delhi'),
    ],
  ),
  WelfareCategory(
    icon: Icons.medical_services_rounded,
    title: 'Free Medicine',
    subtitle: 'Subsidized & free medicine programs',
    color: Color(0xFF4CAF50),
    items: [
      WelfareResource('Jan Aushadhi Kendras', 'PM Bhartiya Janaushadhi — medicines 50–90% cheaper',
          '1800-111-255', '9,000+ outlets across India'),
      WelfareResource('Ayushman Bharat (PMJAY)', 'Free treatment up to ₹5 lakh per family/year at 25,000+ hospitals',
          '14555', 'pmjay.gov.in | Toll Free'),
      WelfareResource('State Free Medicine Scheme', 'Free medicines at government PHCs, CHCs & district hospitals',
          null, 'Contact district CMO office'),
      WelfareResource('NGO Medicine Banks', 'Organizations like Goonj & iCall distribute free medicines',
          '9152987821', 'Pan India'),
    ],
  ),
  WelfareCategory(
    icon: Icons.airport_shuttle_rounded,
    title: 'Ambulance Services',
    subtitle: 'Emergency & patient transport',
    color: Color(0xFF2196F3),
    items: [
      WelfareResource('108 Emergency Ambulance', 'Free government advanced life support — 24/7 response',
          '108', 'Pan India (All states)'),
      WelfareResource('102 Janani Express', 'Free ambulance for pregnant women & newborn transport',
          '102', 'Pan India (Govt-funded)'),
      WelfareResource('EMRI 1298 Ambulance', 'Emergency response — basic & advanced life support units',
          '1298', 'Andhra, Telangana, Gujarat & others'),
      WelfareResource('Ziqitza Healthcare', 'Private ambulance — ICU on wheels & inter-hospital transfers',
          '1800-419-1122', 'Pan India'),
    ],
  ),
  WelfareCategory(
    icon: Icons.home_rounded,
    title: 'Shelters & Welfare Homes',
    subtitle: 'Old age homes, orphanages & women shelters',
    color: Color(0xFF7C3AED),
    items: [
      WelfareResource('HelpAge India', 'Old age homes, elder helpline, legal aid & mobile healthcare for seniors',
          '1800-180-1253', 'Pan India (Toll Free)'),
      WelfareResource('Missionaries of Charity', 'Shelter for destitute, terminally ill & abandoned individuals',
          '033-22271167', 'Kolkata & 250+ centres in India'),
      WelfareResource("SOS Children's Villages India", 'Safe homes & holistic care for orphaned & abandoned children',
          '011-46556300', '32 villages across India'),
      WelfareResource('SWADHAR Greh', 'Government shelter homes for women in distress — free food & legal aid',
          '181', 'Women helpline — Pan India'),
    ],
  ),
  WelfareCategory(
    icon: Icons.account_balance_rounded,
    title: 'Government Welfare Schemes',
    subtitle: 'Central & state support programs',
    color: Color(0xFFFF9800),
    items: [
      WelfareResource('PM KISAN Samman Nidhi', 'Direct ₹6,000/year income support for small & marginal farmers',
          '155261', 'pmkisan.gov.in'),
      WelfareResource('PM Ujjwala Yojana', 'Free LPG connections for BPL households — clean cooking fuel',
          '1800-233-3555', 'pmuy.gov.in'),
      WelfareResource('MGNREGA', '100-day guaranteed rural employment — ₹220–300/day wages',
          null, 'nrega.nic.in | Block office'),
      WelfareResource('National Social Assistance Programme', 'Old age, widow & disability pension for BPL families',
          null, 'nsap.nic.in | District SDO'),
      WelfareResource('PM Awas Yojana', 'Affordable housing scheme for economically weaker sections',
          '1800-11-6163', 'pmaymis.gov.in'),
    ],
  ),
];

// ─── Full-screen welfare resources page ──────────────────────────────────────

class WelfareResourcesScreen extends StatefulWidget {
  const WelfareResourcesScreen({super.key});

  @override
  State<WelfareResourcesScreen> createState() => _WelfareResourcesScreenState();
}

class _WelfareResourcesScreenState extends State<WelfareResourcesScreen> {
  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.surface,
        title: Text('Welfare Resources', style: AidTextStyles.headingMd),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: kWelfareCategories.length + 1,
        separatorBuilder: (_, __) => const Gap(10),
        itemBuilder: (_, i) {
          if (i == 0) return _buildBanner();
          final cat = kWelfareCategories[i - 1];
          final expanded = _expandedIndex == (i - 1);
          return _buildCard(cat, i - 1, expanded);
        },
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AidColors.donorAccent.withValues(alpha: 0.12),
            AidColors.ngoAccent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.donorAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AidColors.donorAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.library_books_rounded, color: AidColors.donorAccent, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('India Welfare Directory', style: AidTextStyles.headingMd),
                const Gap(2),
                Text(
                  'Hospitals · Blood banks · Free medicine · Govt schemes',
                  style: AidTextStyles.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(WelfareCategory cat, int index, bool expanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? cat.color.withValues(alpha: 0.45) : AidColors.borderSubtle,
          width: expanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandedIndex = expanded ? -1 : index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.title, style: AidTextStyles.headingSm),
                        const Gap(1),
                        Text(cat.subtitle, style: AidTextStyles.bodySm),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.items.length}',
                      style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Gap(8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AidColors.textMuted, size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: AidColors.borderSubtle, height: 1, indent: 14, endIndent: 14),
            ...cat.items.asMap().entries.map((e) =>
              _buildItem(e.value, cat.color, e.key == cat.items.length - 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(WelfareResource item, Color color, bool isLast) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AidTextStyles.headingSm),
                    const Gap(3),
                    Text(item.description, style: AidTextStyles.bodySm),
                    const Gap(6),
                    Wrap(
                      spacing: 12, runSpacing: 4,
                      children: [
                        if (item.phone != null)
                          _chip(Icons.phone_rounded, item.phone!, color),
                        _chip(Icons.location_on_outlined, item.location, AidColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const Gap(12),
            const Divider(color: AidColors.borderSubtle, height: 1),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const Gap(4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Compact resources preview widget (used inline in donor feed) ─────────────

class WelfareResourcesPreview extends StatelessWidget {
  const WelfareResourcesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WelfareResourcesScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AidColors.donorAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.library_books_rounded, color: AidColors.donorAccent, size: 18),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welfare Resources', style: AidTextStyles.headingSm),
                      Text('Hospitals, blood banks, govt schemes & more',
                          style: AidTextStyles.bodySm),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AidColors.donorAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Explore', style: TextStyle(
                        color: AidColors.donorAccent, fontSize: 12, fontWeight: FontWeight.w700,
                      )),
                      const Gap(4),
                      const Icon(Icons.arrow_forward_rounded, size: 13, color: AidColors.donorAccent),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            // Category pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kWelfareCategories.map((cat) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: cat.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 13, color: cat.color),
                        const Gap(5),
                        Text(
                          cat.title.split(' ').first,
                          style: TextStyle(
                            color: cat.color, fontSize: 11, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

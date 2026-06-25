import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/data/models/company.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _sortField = 'Name'; // Name, Date, Workers, Sites
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer.withValues(alpha: 0.15),
              context.colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ModuleHeader(
                title: 'System Analytics',
                subtitle: 'Real-time platform statistics & usage',
                showBackButton: true,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('companies').snapshots(),
                  builder: (context, companiesSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('company_requests').snapshots(),
                      builder: (context, requestsSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, usersSnap) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collectionGroup('sites').snapshots(),
                              builder: (context, sitesSnap) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collectionGroup('attendance').snapshots(),
                                  builder: (context, attendanceSnap) {
                                    if (companiesSnap.connectionState == ConnectionState.waiting ||
                                        requestsSnap.connectionState == ConnectionState.waiting ||
                                        usersSnap.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    return _buildAnalyticsContent(
                                      context,
                                      isDark,
                                      companiesSnap.data?.docs ?? [],
                                      requestsSnap.data?.docs ?? [],
                                      usersSnap.data?.docs ?? [],
                                      sitesSnap.data?.docs ?? [],
                                      attendanceSnap.data?.docs ?? [],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    bool isDark,
    List<QueryDocumentSnapshot> companiesDocs,
    List<QueryDocumentSnapshot> requestsDocs,
    List<QueryDocumentSnapshot> usersDocs,
    List<QueryDocumentSnapshot> sitesDocs,
    List<QueryDocumentSnapshot> attendanceDocs,
  ) {
    // 1. KPI Calculations
    final totalCompanies = companiesDocs.length;
    final pendingRequests = requestsDocs.where((d) => d['status'] == 'pending').length;
    final approvedRequests = requestsDocs.where((d) => d['status'] == 'approved').length;
    final rejectedRequests = requestsDocs.where((d) => d['status'] == 'rejected').length;

    final totalOwners = usersDocs.where((d) => d['role'] == 'owner').length;
    final totalSupervisors = usersDocs.where((d) => d['role'] == 'supervisor').length;
    final totalSites = sitesDocs.length;
    final totalAttendance = attendanceDocs.length;

    // Count workers across all companies
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collectionGroup('labour').get(),
      builder: (context, labourSnap) {
        final workersCount = labourSnap.data?.docs.length ?? 0;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // KPI Grid
            _buildKPIGrid(
              context,
              totalCompanies,
              pendingRequests,
              approvedRequests,
              rejectedRequests,
              totalOwners,
              totalSupervisors,
              workersCount,
              totalSites,
              totalAttendance,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Charts Section
            _buildChartsSection(context, isDark, companiesDocs, requestsDocs, usersDocs),
            const SizedBox(height: AppSpacing.lg),

            // Table Section
            _buildCompanyTableSection(context, isDark, companiesDocs, usersDocs, sitesDocs, labourSnap.data?.docs ?? []),
          ],
        );
      },
    );
  }

  Widget _buildKPIGrid(
    BuildContext context,
    int totalCompanies,
    int pendingRequests,
    int approvedRequests,
    int rejectedRequests,
    int totalOwners,
    int totalSupervisors,
    int totalWorkers,
    int totalSites,
    int totalAttendance,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 2 : 1);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      children: [
        _kpiCard(context, 'Total Companies', '$totalCompanies', Icons.business, const Color(0xFF7B4DFF)),
        _kpiCard(context, 'Pending Requests', '$pendingRequests', Icons.pending_actions, Colors.orange),
        _kpiCard(context, 'Approved Requests', '$approvedRequests', Icons.check_circle_outline, Colors.green),
        _kpiCard(context, 'Rejected Requests', '$rejectedRequests', Icons.gpp_bad_outlined, Colors.red),
        _kpiCard(context, 'Total Owners', '$totalOwners', Icons.person_outline, const Color(0xFF3D8BFF)),
        _kpiCard(context, 'Total Supervisors', '$totalSupervisors', Icons.badge_outlined, Colors.purple),
        _kpiCard(context, 'Total Workers', '$totalWorkers', Icons.people_outline, const Color(0xFF00D68F)),
        _kpiCard(context, 'Total Sites', '$totalSites', Icons.location_on_outlined, Colors.blueGrey),
      ],
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    bool isDark,
    List<QueryDocumentSnapshot> companies,
    List<QueryDocumentSnapshot> requests,
    List<QueryDocumentSnapshot> users,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final companyGrowthData = _groupTimestampsByMonth(companies, 'createdAt');
    final requestTrendData = _groupTimestampsByMonth(requests, 'submittedAt');
    final userGrowthData = _groupTimestampsByMonth(users, 'createdAt');

    final companyChart = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company & Requests Trend', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: LineChartPainter(
                  data1: companyGrowthData,
                  data2: requestTrendData,
                  label1: 'Companies Created',
                  label2: 'Requests Submitted',
                  color1: const Color(0xFF7B4DFF),
                  color2: Colors.orange,
                  isDark: isDark,
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );

    final userGrowthChart = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Signup Growth', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: LineChartPainter(
                  data1: userGrowthData,
                  data2: const {},
                  label1: 'User Registrations',
                  label2: '',
                  color1: const Color(0xFF00D68F),
                  color2: Colors.transparent,
                  isDark: isDark,
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: companyChart),
          const SizedBox(width: 16),
          Expanded(child: userGrowthChart),
        ],
      );
    } else {
      return Column(
        children: [
          companyChart,
          const SizedBox(height: 16),
          userGrowthChart,
        ],
      );
    }
  }

  Map<String, double> _groupTimestampsByMonth(List<QueryDocumentSnapshot> docs, String field) {
    final Map<String, double> monthlyCounts = {};
    final now = DateTime.now();

    // Initialize past 6 months to 0
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat('MMM').format(date);
      monthlyCounts[monthLabel] = 0;
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final timestamp = data[field] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        // Only include if within the past 6 months
        final differenceMonths = (now.year - date.year) * 12 + now.month - date.month;
        if (differenceMonths >= 0 && differenceMonths < 6) {
          final monthLabel = DateFormat('MMM').format(date);
          monthlyCounts[monthLabel] = (monthlyCounts[monthLabel] ?? 0) + 1;
        }
      }
    }
    return monthlyCounts;
  }

  Widget _buildCompanyTableSection(
    BuildContext context,
    bool isDark,
    List<QueryDocumentSnapshot> companies,
    List<QueryDocumentSnapshot> users,
    List<QueryDocumentSnapshot> sites,
    List<QueryDocumentSnapshot> labour,
  ) {
    // Compile table details
    List<Map<String, dynamic>> rows = [];
    for (final doc in companies) {
      final company = Company.fromFirestore(doc);
      final ownerDoc = users.firstWhere((u) => u.id == company.ownerUid, orElse: () => doc);
      final ownerName = ownerDoc.id == doc.id ? 'Unknown' : (ownerDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

      // Count stats
      final companySitesCount = sites.where((s) => s.reference.parent.parent?.id == company.id).length;
      final companyLabourCount = labour.where((l) => l.reference.parent.parent?.id == company.id).length;

      rows.add({
        'name': company.name,
        'legalName': company.legalName,
        'owner': ownerName,
        'workers': companyLabourCount,
        'supervisors': users.where((u) => (u.data() as Map<String, dynamic>)['companyId'] == company.id && (u.data() as Map<String, dynamic>)['role'] == 'supervisor').length,
        'sites': companySitesCount,
        'date': company.createdAt ?? DateTime.now(),
        'status': company.isActive ? 'Active' : 'Inactive',
      });
    }

    // Apply Search
    if (_searchQuery.isNotEmpty) {
      rows = rows.where((r) {
        final name = r['name'].toString().toLowerCase();
        final owner = r['owner'].toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || owner.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply Filter
    if (_statusFilter != 'All') {
      rows = rows.where((r) => r['status'] == _statusFilter).toList();
    }

    // Apply Sorting
    rows.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (_sortField) {
        case 'Name':
          valA = a['name'];
          valB = b['name'];
          break;
        case 'Date':
          valA = a['date'];
          valB = b['date'];
          break;
        case 'Workers':
          valA = a['workers'];
          valB = b['workers'];
          break;
        case 'Sites':
          valA = a['sites'];
          valB = b['sites'];
          break;
        default:
          valA = a['name'];
          valB = b['name'];
      }

      if (_sortAscending) {
        return valA.compareTo(valB);
      } else {
        return valB.compareTo(valA);
      }
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Company Overview', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                _buildTableControls(context),
              ],
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No companies match your filters.'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: const Text('Company Name'),
                      onSort: (colIndex, asc) => _setSort('Name', asc),
                    ),
                    DataColumn(
                      label: const Text('Owner'),
                    ),
                    DataColumn(
                      label: const Text('Workers'),
                      numeric: true,
                      onSort: (colIndex, asc) => _setSort('Workers', asc),
                    ),
                    DataColumn(
                      label: const Text('Supervisors'),
                      numeric: true,
                    ),
                    DataColumn(
                      label: const Text('Sites'),
                      numeric: true,
                      onSort: (colIndex, asc) => _setSort('Sites', asc),
                    ),
                    DataColumn(
                      label: const Text('Created Date'),
                      onSort: (colIndex, asc) => _setSort('Date', asc),
                    ),
                    const DataColumn(
                      label: const Text('Status'),
                    ),
                  ],
                  rows: rows.map((r) {
                    final dateStr = DateFormat('dd MMM yyyy').format(r['date'] as DateTime);
                    return DataRow(
                      cells: [
                        DataCell(Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(r['owner'])),
                        DataCell(Text('${r['workers']}')),
                        DataCell(Text('${r['supervisors']}')),
                        DataCell(Text('${r['sites']}')),
                        DataCell(Text(dateStr)),
                        DataCell(Text(r['status'], style: TextStyle(color: r['status'] == 'Active' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableControls(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 38,
          child: TextFormField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search company/owner...',
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _statusFilter,
          items: ['All', 'Active', 'Inactive']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
              });
            }
          },
        ),
      ],
    );
  }

  void _setSort(String field, bool ascending) {
    setState(() {
      _sortField = field;
      _sortAscending = ascending;
    });
  }
}

class LineChartPainter extends CustomPainter {
  final Map<String, double> data1;
  final Map<String, double> data2;
  final String label1;
  final String label2;
  final Color color1;
  final Color color2;
  final bool isDark;

  LineChartPainter({
    required this.data1,
    required this.data2,
    required this.label1,
    required this.label2,
    required this.color1,
    required this.color2,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)), bgPaint);

    if (data1.isEmpty) return;

    final keys = data1.keys.toList();
    final values1 = data1.values.toList();
    final values2 = data2.values.toList();

    double maxValue = 5.0; // Basline max value
    for (final v in values1) {
      if (v > maxValue) maxValue = v;
    }
    for (final v in values2) {
      if (v > maxValue) maxValue = v;
    }

    final double padLeft = 40;
    final double padRight = 20;
    final double padTop = 20;
    final double padBottom = 30;

    final double chartWidth = size.width - padLeft - padRight;
    final double chartHeight = size.height - padTop - padBottom;

    // Draw Y Axis gridlines
    final linePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartHeight * (1.0 - (i / 4));
      final val = (maxValue * (i / 4)).round();
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), linePaint);
      
      final textSpan = TextSpan(
        text: '$val',
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - 6));
    }

    // Draw Data Lines
    _drawTrendLine(canvas, keys, values1, maxValue, padLeft, padTop, chartWidth, chartHeight, color1);
    if (data2.isNotEmpty) {
      _drawTrendLine(canvas, keys, values2, maxValue, padLeft, padTop, chartWidth, chartHeight, color2);
    }

    // Draw X labels
    for (int i = 0; i < keys.length; i++) {
      final double x = padLeft + (chartWidth / (keys.length - 1)) * i;
      final textSpan = TextSpan(
        text: keys[i],
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - padBottom + 8));
    }

    // Draw Legends
    _drawLegend(canvas, size, label1, color1, label2, color2);
  }

  void _drawTrendLine(
    Canvas canvas,
    List<String> keys,
    List<double> values,
    double maxValue,
    double padLeft,
    double padTop,
    double chartWidth,
    double chartHeight,
    Color color,
  ) {
    final path = Path();
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < keys.length; i++) {
      final double x = padLeft + (chartWidth / (keys.length - 1)) * i;
      final double y = padTop + chartHeight * (1.0 - (values[i] / maxValue));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(path, strokePaint);
  }

  void _drawLegend(Canvas canvas, Size size, String l1, Color c1, String l2, Color c2) {
    // Render legend labels at the top-right corner
    final fontStyle = TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 9, fontWeight: FontWeight.bold);

    // Legend 1
    final span1 = TextSpan(text: l1, style: fontStyle);
    final painter1 = TextPainter(text: span1, textDirection: TextDirection.ltr);
    painter1.layout();

    final double yOffset = 4;
    final double l1X = size.width - 20 - painter1.width;
    canvas.drawRect(Rect.fromLTWH(l1X - 14, yOffset + 3, 8, 8), Paint()..color = c1);
    painter1.paint(canvas, Offset(l1X, yOffset));

    // Legend 2
    if (l2.isNotEmpty) {
      final span2 = TextSpan(text: l2, style: fontStyle);
      final painter2 = TextPainter(text: span2, textDirection: TextDirection.ltr);
      painter2.layout();

      final double l2X = l1X - 30 - painter2.width;
      canvas.drawRect(Rect.fromLTWH(l2X - 14, yOffset + 3, 8, 8), Paint()..color = c2);
      painter2.paint(canvas, Offset(l2X, yOffset));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data1 != data1 || oldDelegate.data2 != data2;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tution_class.dart';
import '../models/payment.dart';
import '../services/data_service.dart';
import '../services/notification_service_simple.dart';
import 'timetable_screen.dart';
import 'home_screen.dart';

class FeesScreen extends StatefulWidget {
  final List<TutionClass> classes;
  final Function(int)? onNavigate;

  const FeesScreen({super.key, required this.classes, this.onNavigate});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> with TickerProviderStateMixin {
  late String selectedMonth;
  List<Payment> payments = [];
  int _selectedIndex = 2; // Courses tab is selected (where fees are now)
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    // Set current month dynamically
    selectedMonth = _dataService.getCurrentMonth();
    _setupAnimations();
    _initializeData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  Future<void> _initializeData() async {
    try {
      await _dataService.initializeHive();
      await _generatePaymentsForCurrentMonth();
      _loadPayments();
      
      // Initialize notifications in background (don't block UI)
      _notificationService.initialize().then((_) {
        // Check and schedule overdue notifications after initialization
        return _notificationService.checkAndScheduleOverdueNotifications();
      }).catchError((e) {
        print('Notification initialization failed in fees screen: $e');
        // Continue without notifications
      });
    } catch (e) {
      print('Error initializing fees screen data: $e');
      // Show empty state if data loading fails
      setState(() {
        payments = [];
      });
    }
  }

  Future<void> _generatePaymentsForCurrentMonth() async {
    final now = DateTime.now();
    await _dataService.generatePaymentsForMonth(selectedMonth, now.year);
  }

  void _loadPayments() {
    setState(() {
      // Use the new method that includes overdue payments from previous months
      payments = _dataService.getPaymentsForCurrentView();
    });
  }

  double get totalOutstanding {
    return payments.where((p) => !p.isPaid).fold(0, (sum, p) => sum + p.amount);
  }

  double get totalThisMonth {
    // Only current month payments for this calculation
    final currentMonthPayments = payments.where((p) => 
      p.month == selectedMonth && p.year == _dataService.getCurrentYear()).toList();
    return currentMonthPayments.fold(0, (sum, p) => sum + p.amount);
  }

  double get totalPaid {
    return payments.where((p) => p.isPaid).fold(0, (sum, p) => sum + p.amount);
  }

  double get totalOverdue {
    final now = DateTime.now();
    return payments.where((p) => !p.isPaid && p.dueDate.isBefore(now))
        .fold(0, (sum, p) => sum + p.amount);
  }

  Future<void> _togglePaymentStatus(Payment payment) async {
    await _dataService.updatePaymentStatus(payment.id, !payment.isPaid);
    _loadPayments(); // Reload to reflect changes
    
    // Update notifications after payment status change
    await _notificationService.checkAndScheduleOverdueNotifications();
    
    // Show feedback with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              payment.isPaid ? Icons.schedule : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                payment.isPaid 
                    ? "Payment marked as unpaid" 
                    : "Payment marked as paid!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: payment.isPaid ? Colors.orange[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      // Navigate to Timetable
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TimetableScreen(
            onNavigate: widget.onNavigate,
          ),
        ),
      );
    } else if (index == 3) {
      // Profile - can be implemented later
    }
    // For fees/courses (index 2), do nothing as we're already here
  }

  Future<void> _onMonthChanged(String? newMonth) async {
    if (newMonth != null && newMonth != selectedMonth) {
      setState(() {
        selectedMonth = newMonth;
      });
      
      // Generate payments for the new month if they don't exist
      final now = DateTime.now();
      await _dataService.generatePaymentsForMonth(selectedMonth, now.year);
      _loadPayments();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Fee Management",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2A66F2)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A66F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF2A66F2),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // Temporarily removed notification button while notifications are disabled
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _outstandingBalanceCard(),
                    const SizedBox(height: 16),
                    _monthlySummaryCard(),
                    const SizedBox(height: 24),
                    _paymentHistoryHeader(),
                    const SizedBox(height: 16),
                    if (payments.isEmpty)
                      _emptyPaymentsWidget()
                    else
                      ...payments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final payment = entry.value;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: _paymentCard(payment),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildInfoCard() {
    final overdueCount = payments.where((p) => !p.isPaid && p.isOverdue).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: overdueCount > 0 
              ? [Colors.orange[50]!, Colors.red[50]!]
              : [Colors.blue[50]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdueCount > 0 
              ? Colors.orange[200]!
              : const Color(0xFF2A66F2).withOpacity(0.2)
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: overdueCount > 0 
                  ? Colors.orange[100]
                  : const Color(0xFF2A66F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              overdueCount > 0 ? Icons.warning_outlined : Icons.info_outline,
              color: overdueCount > 0 ? Colors.orange[600] : const Color(0xFF2A66F2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overdueCount > 0 
                      ? "Overdue Payments Found!"
                      : "How Monthly Fees Work",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: overdueCount > 0 ? Colors.orange[800] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overdueCount > 0
                      ? "You have $overdueCount overdue payments from previous months. Please pay them as soon as possible."
                      : "Fees are due from 1st to last day of each month. Overdue payments from previous months are shown here.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: overdueCount > 0 ? Colors.orange[700] : Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outstandingBalanceCard() {
    final overdueAmount = totalOverdue;
    final hasOverdue = overdueAmount > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasOverdue 
              ? [Colors.red[600]!, Colors.red[700]!]
              : [const Color(0xFF2A66F2), const Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasOverdue ? Colors.red[600]! : const Color(0xFF2A66F2)).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasOverdue ? Icons.warning : Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasOverdue ? "Total Outstanding" : "Outstanding Balance",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "LKR ${totalOutstanding.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (hasOverdue)
                      Text(
                        "Including LKR ${overdueAmount.toStringAsFixed(0)} overdue",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: "$selectedMonth Fees",
              amount: totalThisMonth,
              color: Colors.black87,
              icon: Icons.calendar_month,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: "Total Paid",
              amount: totalPaid,
              color: Colors.green[600]!,
              icon: Icons.check_circle,
            ),
          ),
          if (totalOverdue > 0) ...[
            Container(
              height: 40,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Expanded(
              child: _summaryItem(
                title: "Overdue",
                amount: totalOverdue,
                color: Colors.red[600]!,
                icon: Icons.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "LKR ${amount.toStringAsFixed(0)}",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _paymentHistoryHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment History",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Current month + overdue payments",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMonth,
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(
                    month,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onMonthChanged,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF2A66F2),
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentCard(Payment payment) {
    final isOverdue = payment.isOverdue;
    final isFromPreviousMonth = payment.month != selectedMonth || payment.year != _dataService.getCurrentYear();
    
    Color statusColor;
    if (payment.isPaid) {
      statusColor = Colors.green[600]!;
    } else if (isOverdue) {
      statusColor = Colors.red[600]!;
    } else {
      statusColor = const Color(0xFFFFB800);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue && !payment.isPaid 
            ? Border.all(color: Colors.red[300]!, width: 2)
            : (isFromPreviousMonth && !payment.isPaid
                ? Border.all(color: Colors.orange[300]!, width: 1)
                : null),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _togglePaymentStatus(payment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    payment.isPaid 
                        ? Icons.check_circle 
                        : (isOverdue ? Icons.warning : Icons.schedule),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.subject,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFromPreviousMonth)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${payment.month} ${payment.year}",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.teacher,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.isPaid 
                            ? "Paid on ${payment.paymentDate.day}/${payment.paymentDate.month}"
                            : (isOverdue 
                                ? "Overdue since ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}"
                                : "Due by ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}"),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "LKR ${payment.amount.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPaymentsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 30,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No Payments Yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add classes to see payment records for $selectedMonth",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF2A66F2),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            items: [
              _buildNavItem(Icons.home, Icons.home_outlined, "Home", 0),
              _buildNavItem(Icons.calendar_month, Icons.calendar_month_outlined, "Timetable", 1),
              _buildNavItem(Icons.school, Icons.school_outlined, "Courses", 2),
              _buildNavItem(Icons.person, Icons.person_outline, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color(0xFF2A66F2).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _selectedIndex == index ? selectedIcon : unselectedIcon,
          size: 24,
        ),
      ),
      label: label,
    );
  }
}
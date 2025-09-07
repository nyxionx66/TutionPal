import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/study_timer_service.dart';
import '../models/tution_class.dart';
import '../screens/add_study_session_screen.dart';

class StudyTimerWidget extends StatefulWidget {
  final List<TutionClass> classes;

  const StudyTimerWidget({super.key, required this.classes});

  @override
  State<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}

class _StudyTimerWidgetState extends State<StudyTimerWidget> {
  final StudyTimerService _timerService = StudyTimerService();
  String? selectedSubject;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeTimerService();
  }

  Future<void> _initializeTimerService() async {
    try {
      await _timerService.initialize();
      setState(() {}); // Refresh UI after initialization
    } catch (e) {
      print('Error initializing study timer service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (isExpanded) ...[
            _buildTimerControls(),
            if (widget.classes.isNotEmpty) _buildSubjectSelector(),
            _buildStudyStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A66F2), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A66F2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Timer',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<bool>(
                      stream: _timerService.isRunningStream,
                      builder: (context, snapshot) {
                        final isRunning = snapshot.data ?? false;
                        if (isRunning) {
                          return StreamBuilder<int>(
                            stream: _timerService.timerStream,
                            builder: (context, timerSnapshot) {
                              final seconds = timerSnapshot.data ?? 0;
                              return Text(
                                'Running: ${_timerService.formatDuration(seconds)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[600],
                                ),
                              );
                            },
                          );
                        } else {
                          return Text(
                            'Track your study sessions',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF2A66F2),
                size: 24,
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    if (widget.classes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Add classes first to track study sessions',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.orange[600],
                        ),
                      );
                      return;
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStudySessionScreen(classes: widget.classes),
                      ),
                    );

                    if (result == true) {
                      setState(() {}); // Refresh the stats
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A66F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: const Color(0xFF2A66F2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manual',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2A66F2),
                          ),
                        ),
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

  Widget _buildTimerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2A66F2).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                StreamBuilder<int>(
                  stream: _timerService.timerStream,
                  builder: (context, snapshot) {
                    final seconds = snapshot.data ?? 0;
                    return Text(
                      _timerService.formatDuration(seconds),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A66F2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                StreamBuilder<String?>(
                  stream: Stream.periodic(const Duration(seconds: 1), (i) => _timerService.currentSubject),
                  builder: (context, snapshot) {
                    final subject = snapshot.data ?? selectedSubject;
                    if (subject != null) {
                      return Text(
                        'Studying: $subject',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      );
                    }
                    return Text(
                      'Select a subject to start',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildTimerButtons(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimerButtons() {
    return StreamBuilder<bool>(
      stream: _timerService.isRunningStream,
      builder: (context, runningSnapshot) {
        final isRunning = runningSnapshot.data ?? false;
        
        return StreamBuilder<bool>(
          stream: _timerService.isPausedStream,
          builder: (context, pausedSnapshot) {
            final isPaused = pausedSnapshot.data ?? false;
            
            return Row(
              children: [
                if (!isRunning) ...[
                  // Start button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedSubject != null
                          ? () => _timerService.startTimer(selectedSubject!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A66F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        'Start',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Pause/Resume button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isPaused 
                          ? _timerService.resumeTimer 
                          : _timerService.pauseTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPaused ? Colors.green[600] : Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        size: 20,
                      ),
                      label: Text(
                        isPaused ? 'Resume' : 'Pause',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stop button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _timerService.stopTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.stop, size: 20),
                      label: Text(
                        'Stop',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Subject',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSubject,
                hint: Text(
                  'Choose a subject...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                isExpanded: true,
                items: widget.classes.map((tutionClass) {
                  return DropdownMenuItem<String>(
                    value: tutionClass.subject,
                    child: Text(
                      tutionClass.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF2A66F2),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStudyStats() {
    final todayHours = _timerService.getTotalStudyTimeToday();
    final weekHours = _timerService.getTotalStudyTimeThisWeek();
    final todaySessions = _timerService.getTotalSessionsToday();
    final weekSessions = _timerService.getTotalSessionsThisWeek();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Today',
                  hours: todayHours,
                  sessions: todaySessions,
                  color: Colors.green[600]!,
                  icon: Icons.today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  title: 'This Week',
                  hours: weekHours,
                  sessions: weekSessions,
                  color: const Color(0xFF2A66F2),
                  icon: Icons.calendar_view_week,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required double hours,
    required int sessions,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${hours.toStringAsFixed(1)}h',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$sessions session${sessions != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Note: Don't dispose the timer service here as it's a singleton
    super.dispose();
  }
}
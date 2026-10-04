import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../models/user.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final AppUser user;
  final String schoolId;

  const ActivitiesScreen({
    Key? key,
    required this.user,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ActivityService _activityService = ActivityService();

  List<Activity> _upcomingActivities = [];
  List<Activity> _recentActivities = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print('🔄 ActivitiesScreen: Loading activities for school ${widget.schoolId}');

      final upcoming = await _activityService.getUpcomingActivities(widget.schoolId);
      final recent = await _activityService.getRecentActivities(widget.schoolId);

      if (mounted) {
        setState(() {
          _upcomingActivities = upcoming;
          _recentActivities = recent;
          _isLoading = false;
        });
      }

      print('✅ ActivitiesScreen: Loaded ${upcoming.length} upcoming and ${recent.length} recent activities');
    } catch (e) {
      print('❌ ActivitiesScreen: Error loading activities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _joinActivity(Activity activity) async {
    try {
      await _activityService.joinActivity(widget.schoolId, activity.id, widget.user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${activity.title}!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadActivities();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveActivity(Activity activity) async {
    try {
      await _activityService.leaveActivity(widget.schoolId, activity.id, widget.user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully left ${activity.title}'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadActivities();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(
          activity: activity,
          user: widget.user,
          schoolId: widget.schoolId,
        ),
      ),
    ).then((_) {

      _loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading activities...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load activities'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActivities,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (_upcomingActivities.isNotEmpty) ...[
              Text(
                'Upcoming Activities',
                style: GoogleFonts.questrial(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              ..._upcomingActivities.map((activity) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ActivityCard(
                  activity: activity,
                  currentUser: widget.user,
                  onTap: () => _openActivityDetail(activity),
                  onJoin: () => _joinActivity(activity),
                  onLeave: () => _leaveActivity(activity),
                ),
              )),
              SizedBox(height: 24),
            ],

            if (_recentActivities.isNotEmpty) ...[
              Text(
                'Recent Activities',
                style: GoogleFonts.questrial(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              ..._recentActivities.map((activity) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ActivityCard(
                  activity: activity,
                  currentUser: widget.user,
                  onTap: () => _openActivityDetail(activity),
                  showJoinButton: false,
                ),
              )),
            ],

            if (_upcomingActivities.isEmpty && _recentActivities.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No activities available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later for new activities!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
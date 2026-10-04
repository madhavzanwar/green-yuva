import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/activity_service.dart';
import '../services/user_service.dart';
import '../services/school_service.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comments_screen.dart';
import 'activities_screen.dart';
import '../utils/transitions.dart';
import '../utils/performance_optimizer.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class CommunityScreen extends StatefulWidget {
  final AppUser user;
  final String schoolId;
  final VoidCallback? onSchoolLeft;

  const CommunityScreen({
    Key? key,
    required this.user,
    required this.schoolId,
    this.onSchoolLeft,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  final PostService _postService = PostService();
  final ActivityService _activityService = ActivityService();
  final UserService _userService = UserService();
  final SchoolService _schoolService = SchoolService();

  List<PostWithUser> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _schoolName;
  String? _schoolImageUrl;

  final ScrollController _scrollController = ScrollController();
  static const double _expandedHeight = 180.0;
  static const double _collapsedHeight = kToolbarHeight;

  late AnimationController _centerTitleController;
  late AnimationController _leftTitleController;
  late AnimationController _backgroundController;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _centerTitleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _leftTitleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadData();
    _loadSchoolName();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _centerTitleController.dispose();
    _leftTitleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final maxScroll = _expandedHeight - _collapsedHeight;
    final progress = (offset / maxScroll).clamp(0.0, 1.0);

    setState(() {
      _scrollOffset = offset;
    });

    _centerTitleController.value = 1.0 - progress;
    _leftTitleController.value = progress;
    _backgroundController.value = 1.0 - progress;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('🔄 Community: Loading posts and activities for school ${widget.schoolId}');

      final results = await Future.wait([
        _postService.getPostsWithUserInfo(widget.schoolId),
        _activityService.getActivities(widget.schoolId),
      ]);

      final posts = results[0] as List<PostWithUser>;
      final activities = results[1] as List<Activity>;

      print('✅ Community: Loaded ${posts.length} posts and ${activities.length} activities');

      if (posts.isEmpty && activities.isEmpty) {
        print('📝 Community: No data found, loading fallback data');
        _loadFallbackData();
        return;
      }

      setState(() {
        _posts = posts;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Community: Error loading data: $e');
      print('📝 Community: Loading fallback data');

      _loadFallbackData();
    }
  }

  void _loadFallbackData() async {
    print('📝 Community: Loading fallback sample data');

    try {

      await _userService.ensureDummyUsersExist();

      await Future.wait([
        _postService.createSamplePosts(widget.schoolId),
        _activityService.createSchoolSpecificActivities(widget.schoolId),
      ]);

      final results = await Future.wait([
        _postService.getPostsWithUserInfo(widget.schoolId),
        _activityService.getActivities(widget.schoolId),
      ]);

      final posts = results[0] as List<PostWithUser>;
      final activities = results[1] as List<Activity>;

      if (mounted) {
        setState(() {
          _posts = posts;
          _activities = activities;
          _isLoading = false;
        });
        print('✅ Community: Fallback data loaded successfully');
      }
    } catch (e) {
      print('❌ Community: Error loading fallback data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadSchoolName() async {
    try {
      print('🔄 Community: Loading school data for school ID: ${widget.schoolId}');
      final school = await _schoolService.getSchoolById(widget.schoolId);
      if (mounted) {
        setState(() {
          _schoolName = school?.name ?? 'Unknown School';
          _schoolImageUrl = school?.imageUrl;
        });
        print('✅ Community: School data loaded: $_schoolName, image: $_schoolImageUrl');
      }
    } catch (e) {
      print('❌ Community: Error loading school data: $e');
      if (mounted) {
        setState(() {
          _schoolName = 'Unknown School';
          _schoolImageUrl = null;
        });
      }
    }
  }

  String _getSchoolName() {
    return _schoolName ?? 'Loading...';
  }

  Widget _buildSchoolHeaderImage() {
    if (_schoolImageUrl == null || _schoolImageUrl!.isEmpty) {

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
      );
    }

    if (_schoolImageUrl!.startsWith('assets/images/')) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          image: DecorationImage(
            image: AssetImage(_schoolImageUrl!),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        image: DecorationImage(
          image: NetworkImage(_schoolImageUrl!),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Future<void> _leaveSchool() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave School'),
        content: const Text('Are you sure you want to leave this school?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.joinSchool(widget.user.id, '');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the school'),
            backgroundColor: Colors.orange,
          ),
        );

        widget.onSchoolLeft?.call();

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave school: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateCommentCount(String postId, int newCount) {
    final postIndex = _posts.indexWhere((p) => p.post.id == postId);
    if (postIndex != -1) {
      setState(() {
        final currentPostWithUser = _posts[postIndex];
        _posts[postIndex] = PostWithUser(
          post: Post(
            id: currentPostWithUser.post.id,
            userId: currentPostWithUser.post.userId,
            content: currentPostWithUser.post.content,
            imageUrl: currentPostWithUser.post.imageUrl,
            timestamp: currentPostWithUser.post.timestamp,
            likes: currentPostWithUser.post.likes,
            saves: currentPostWithUser.post.saves,
            commentCount: newCount,
          ),
          userName: currentPostWithUser.userName,
        );
      });
    }
  }

  void _navigateHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
      if (mainScreenState != null) {
        mainScreenState.onItemTapped(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.paperCream,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: NeoBackButton(
                    onPressed: _navigateHome,
                  ),
                ),
              ),
              title: AnimatedBuilder(
                animation: _leftTitleController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _leftTitleController.value,
                                          child: Text(
                        _getSchoolName(),
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color(0xFFE3F2FD),
                            ),
                          ],
                        ),
                      ),
                  );
                },
              ),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxExtent = constraints.maxHeight;
                  final double minExtent = kToolbarHeight;
                  final double t = ((maxExtent - minExtent) / (_expandedHeight - _collapsedHeight)).clamp(0.0, 1.0);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedOpacity(
                        opacity: t,
                        duration: const Duration(milliseconds: 200),
                        child: _buildSchoolHeaderImage(),
                      ),
                      AnimatedOpacity(
                        opacity: t,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: 0,
                        right: 0,
                        top: -20 * (1.0 - t),
                        bottom: 0,
                        child: AnimatedOpacity(
                          opacity: t,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            child: Center(
                              child: Text(
                                _getSchoolName(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2.0, 2.0),
                                      blurRadius: 4.0,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: 16,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: AnimatedOpacity(
                          opacity: 1.0 - t,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _getSchoolName(),
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.1,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 3.0,
                                      color: Color(0xFFE3F2FD),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _leaveSchool();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Leave School'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Posts', 0),
                      _buildTabButton('Activities', 1),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _buildPostsTab(),
            _buildActivitiesTab(),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 115),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    AppTransitions.slideFromBottom(CreatePostScreen(
                      schoolId: widget.schoolId,
                      user: widget.user,
                    )),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2.5, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: AppColors.solidBlack, size: 28),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.butterYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: AppColors.solidBlack, width: 1.8) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.solidBlack,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading community content...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to load posts and activities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_posts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Recent Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                             PerformanceOptimizer.optimizeList(
                 ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _posts.length,
                               itemBuilder: (context, index) {
                   final postWithUser = _posts[index];
                   final post = postWithUser.post;
                   final liked = post.likes.contains(widget.user.id);
                   final saved = post.saves.contains(widget.user.id);

                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                     child: PostCard(
                       postWithUser: postWithUser,
                       currentUser: widget.user,
                       liked: liked,
                       saved: saved,
                       onLike: () async {

                         final postIndex = _posts.indexWhere((p) => p.post.id == post.id);
                         if (postIndex != -1) {
                           setState(() {
                             if (liked) {
                               _posts[postIndex].post.likes.remove(widget.user.id);
                             } else {
                               _posts[postIndex].post.likes.add(widget.user.id);
                             }
                           });
                         }

                         try {
                           if (liked) {
                             await _postService.unlikePost(widget.schoolId, post.id, widget.user.id);
                           } else {
                             await _postService.likePost(widget.schoolId, post.id, widget.user.id);
                           }

                         } catch (e) {

                           if (postIndex != -1) {
                             setState(() {
                               if (liked) {
                                 _posts[postIndex].post.likes.add(widget.user.id);
                               } else {
                                 _posts[postIndex].post.likes.remove(widget.user.id);
                               }
                             });
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Failed to ${liked ? 'unlike' : 'like'} post'), backgroundColor: Colors.red),
                           );
                         }
                       },
                       onSave: () async {

                         final postIndex = _posts.indexWhere((p) => p.post.id == post.id);
                         if (postIndex != -1) {
                           setState(() {
                             if (saved) {
                               _posts[postIndex].post.saves.remove(widget.user.id);
                             } else {
                               _posts[postIndex].post.saves.add(widget.user.id);
                             }
                           });
                         }

                         try {
                           if (saved) {
                             await _postService.unsavePost(widget.schoolId, post.id, widget.user.id);
                           } else {
                             await _postService.savePost(widget.schoolId, post.id, widget.user.id);
                           }

                         } catch (e) {

                           if (postIndex != -1) {
                             setState(() {
                               if (saved) {
                                 _posts[postIndex].post.saves.add(widget.user.id);
                               } else {
                                 _posts[postIndex].post.saves.remove(widget.user.id);
                               }
                             });
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Failed to ${saved ? 'unsave' : 'save'} post'), backgroundColor: Colors.red),
                           );
                         }
                       },
                       onComment: () async {
                         final result = await Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => CommentsScreen(
                               post: post,
                               currentUser: widget.user,
                               schoolId: widget.schoolId,
                             ),
                           ),
                         );

                         if (result == true) {
                           _updateCommentCount(post.id, post.commentCount + 1);
                         }
                       },
                       onDelete: () async {

                         final postIndex = _posts.indexWhere((p) => p.post.id == post.id);
                         if (postIndex != -1) {
                           setState(() {
                             _posts.removeAt(postIndex);
                           });
                         }

                         try {
                           await _postService.deletePost(widget.schoolId, post.id);

                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text('Post deleted successfully'),
                               backgroundColor: Colors.green,
                             ),
                           );
                         } catch (e) {

                           if (postIndex != -1) {

                             _loadData();
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text('Failed to delete post'),
                               backgroundColor: Colors.red,
                             ),
                           );
                         }
                       },
                     ),
                   );
                 },
              ),
            ),
            ],

            if (_posts.isEmpty)
              _buildEmptyState(),

            const SizedBox(height: 120), // Padding for floating bottom navbar
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return ActivitiesScreen(
      user: widget.user,
      schoolId: widget.schoolId,
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Content Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share a post or activity!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Refresh'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    print('🔧 Debug: Manually creating sample data for school ${widget.schoolId}');
                    try {
                      await Future.wait([
                        _postService.createSamplePosts(widget.schoolId),
                        _activityService.createSchoolSpecificActivities(widget.schoolId),
                      ]);
                      print('✅ Debug: Sample data created successfully');
                      _loadData();
                    } catch (e) {
                      print('❌ Debug: Error creating sample data: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating sample data: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Sample Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
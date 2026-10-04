import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/user_service.dart';

class PostWithUser {
  final Post post;
  final String userName;

  PostWithUser({
    required this.post,
    required this.userName,
  });
}

class PostService {
  CollectionReference getPostsCollection(String schoolId) {
    return FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('posts');
  }

  Future<List<Post>> getPosts(String schoolId, {int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      print('📊 PostService: Fetching posts for school $schoolId');
      Query query = getPostsCollection(schoolId).orderBy('timestamp', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final posts = snapshot.docs.map((doc) =>
        Post.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();

      print('✅ PostService: Successfully fetched ${posts.length} posts');
      return posts;
    } catch (e) {
      print('❌ PostService: Error fetching posts: $e');

      return [];
    }
  }

  Future<List<PostWithUser>> getPostsWithUserInfo(String schoolId, {int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      print('📊 PostService: Fetching posts with user info for school $schoolId');
      final posts = await getPosts(schoolId, limit: limit, startAfter: startAfter);

      final postsWithUserInfo = <PostWithUser>[];
      for (final post in posts) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(post.userId).get();
          String userName = 'Community Member';

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            userName = '$firstName $lastName'.trim();
            if (userName.isEmpty) userName = 'Community Member';
          }

          postsWithUserInfo.add(PostWithUser(
            post: post,
            userName: userName,
          ));
        } catch (e) {
          print('⚠️ PostService: Error getting user info for post ${post.id}: $e');
          postsWithUserInfo.add(PostWithUser(
            post: post,
            userName: 'Community Member',
          ));
        }
      }

      print('✅ PostService: Successfully fetched ${postsWithUserInfo.length} posts with user info');
      return postsWithUserInfo;
    } catch (e) {
      print('❌ PostService: Error fetching posts with user info: $e');
      return [];
    }
  }

  Future<void> addPost(String schoolId, Post post) async {
    try {
      print('📝 PostService: Adding post to school $schoolId');

      final schoolDoc = FirebaseFirestore.instance.collection('schools').doc(schoolId);
      final schoolSnapshot = await schoolDoc.get();

      if (!schoolSnapshot.exists) {
        print('⚠️ PostService: School document does not exist, creating it...');
        await schoolDoc.set({
          'name': 'School $schoolId',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await getPostsCollection(schoolId).doc(post.id).set(post.toMap());
      print('✅ PostService: Post added successfully');
    } catch (e) {
      print('❌ PostService: Error adding post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String schoolId, String postId) async {
    try {
      print('🗑️ PostService: Deleting post $postId from school $schoolId');
      await getPostsCollection(schoolId).doc(postId).delete();
      print('✅ PostService: Post deleted successfully');
    } catch (e) {
      print('❌ PostService: Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> likePost(String schoolId, String postId, String userId) async {
    try {
      await getPostsCollection(schoolId).doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  Future<void> unlikePost(String schoolId, String postId, String userId) async {
    try {
      await getPostsCollection(schoolId).doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error unliking post: $e');
      rethrow;
    }
  }

  Future<void> savePost(String schoolId, String postId, String userId) async {
    try {
      await getPostsCollection(schoolId).doc(postId).update({
        'saves': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error saving post: $e');
      rethrow;
    }
  }

  Future<void> unsavePost(String schoolId, String postId, String userId) async {
    try {
      await getPostsCollection(schoolId).doc(postId).update({
        'saves': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error unsaving post: $e');
      rethrow;
    }
  }

  Future<void> addComment(String schoolId, String postId, Comment comment) async {
    try {
      await getPostsCollection(schoolId).doc(postId).collection('comments').doc(comment.id).set(comment.toMap());
      try {
        await getPostsCollection(schoolId).doc(postId).update({
          'commentCount': FieldValue.increment(1),
        });
      } catch (_) {}
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Future<List<Comment>> getComments(String schoolId, String postId) async {
    try {
      final snapshot = await getPostsCollection(schoolId).doc(postId).collection('comments').orderBy('timestamp', descending: false).get();
      return snapshot.docs.map((doc) => Comment.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<void> createSamplePosts(String schoolId) async {
    try {
      print('📝 PostService: Creating sample posts for school $schoolId');

      final schoolDoc = FirebaseFirestore.instance.collection('schools').doc(schoolId);
      final schoolSnapshot = await schoolDoc.get();

      if (!schoolSnapshot.exists) {
        print('⚠️ PostService: School document does not exist, creating it...');
        await schoolDoc.set({
          'name': 'School $schoolId',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final userService = UserService();
      await userService.ensureDummyUsersExist();

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) {
        print('⚠️ PostService: No users found in Firebase, cannot create sample posts');
        return;
      }

      final samplePosts = [
        Post(
          id: 'sample_post_1',
          userId: userIds.isNotEmpty ? userIds[0] : 'dummy_user_1',
          content: 'Just completed the Climate Quiz! 🌱 Learned so much about renewable energy. Who else is taking action for our planet?',
          imageUrl: null,
          likes: userIds.length > 1 ? [userIds[1]] : [],
          saves: userIds.isNotEmpty ? [userIds[0]] : [],
          commentCount: 3,
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
        Post(
          id: 'sample_post_2',
          userId: userIds.length > 1 ? userIds[1] : 'dummy_user_2',
          content: 'Our school\'s recycling program is making a huge difference! We\'ve collected over 500kg of recyclables this month. 🚮♻️',
          imageUrl: null,
          likes: userIds.length > 2 ? [userIds[0], userIds[2]] : [],
          saves: userIds.length > 1 ? [userIds[1]] : [],
          commentCount: 5,
          timestamp: DateTime.now().subtract(Duration(hours: 5)),
        ),
        Post(
          id: 'sample_post_3',
          userId: userIds.length > 2 ? userIds[2] : 'dummy_user_3',
          content: 'Excited to join the tree planting event next week! 🌳 Let\'s make our community greener together.',
          imageUrl: null,
          likes: userIds.length > 1 ? [userIds[0], userIds[1]] : [],
          saves: userIds.length > 2 ? [userIds[2]] : [],
          commentCount: 2,
          timestamp: DateTime.now().subtract(Duration(hours: 8)),
        ),
      ];

      for (final post in samplePosts) {
        await addPost(schoolId, post);
      }

      print('✅ PostService: Sample posts created successfully with real user IDs');
    } catch (e) {
      print('❌ PostService: Error creating sample posts: $e');
      rethrow;
    }
  }
}
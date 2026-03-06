import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/feed_post_model.dart';
import 'package:lingafriq/models/feed_profile_model.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class XFeedState {
  final bool loading;
  final List<FeedPostModel> posts;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> lists;
  final List<Map<String, dynamic>> trending;
  final FeedProfileModel? profile;
  final String? errorMessage;

  const XFeedState({
    required this.loading,
    required this.posts,
    required this.notifications,
    required this.lists,
    required this.trending,
    this.profile,
    this.errorMessage,
  });

  factory XFeedState.initial() => const XFeedState(
        loading: false,
        posts: [],
        notifications: [],
        lists: [],
        trending: [],
        profile: null,
        errorMessage: null,
      );

  XFeedState copyWith({
    bool? loading,
    List<FeedPostModel>? posts,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? lists,
    List<Map<String, dynamic>>? trending,
    FeedProfileModel? profile,
    String? errorMessage,
  }) {
    return XFeedState(
      loading: loading ?? this.loading,
      posts: posts ?? this.posts,
      notifications: notifications ?? this.notifications,
      lists: lists ?? this.lists,
      trending: trending ?? this.trending,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

class XFeedNotifier extends Notifier<XFeedState> {
  @override
  XFeedState build() => XFeedState.initial();

  Future<void> loadTimeline({String mode = 'for_you'}) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final response = await ApiService.get(
        ApiContract.url(ApiContract.feed.posts),
        queryParameters: {'mode': mode, 'limit': 30},
      );
      final rows = _extractList(response.data);
      state = state.copyWith(
        loading: false,
        posts: rows.map((row) => FeedPostModel.fromJson(row)).toList(),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading X feed timeline', tag: 'x-feed', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load your timeline.');
    }
  }

  Future<bool> composePost({
    required String content,
    String type = 'text',
    String visibility = 'public',
  }) async {
    final optimistic = FeedPostModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'me',
      content: content,
      type: type,
      likeCount: 0,
      replyCount: 0,
      repostCount: 0,
      viewCount: 0,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(posts: [optimistic, ...state.posts], errorMessage: null);
    try {
      final response = await ApiService.post(
        ApiContract.url(ApiContract.feed.posts),
        data: {
          'content': content,
          'type': type,
          'visibility': visibility,
        },
      );
      final payload = _extractMap(response.data);
      final created = _extractMap(payload['data']);
      final createdPost = created.isNotEmpty ? FeedPostModel.fromJson(created) : optimistic;
      state = state.copyWith(
        posts: [
          createdPost,
          ...state.posts.where((p) => p.id != optimistic.id),
        ],
      );
      return true;
    } catch (error) {
      logger.error('Failed composing post', tag: 'x-feed', error: error);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != optimistic.id).toList(),
        errorMessage: 'Could not publish your post.',
      );
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final before = state.posts[index];
    final optimistic = FeedPostModel(
      id: before.id,
      authorId: before.authorId,
      content: before.content,
      type: before.type,
      likeCount: before.likeCount + 1,
      replyCount: before.replyCount,
      repostCount: before.repostCount,
      viewCount: before.viewCount,
      createdAt: before.createdAt,
    );
    final updatedList = [...state.posts];
    updatedList[index] = optimistic;
    state = state.copyWith(posts: updatedList);

    try {
      final response = await ApiService.post(ApiContract.url(ApiContract.feed.postLike(postId)));
      final payload = _extractMap(response.data);
      final data = _extractMap(payload['data']);
      final liked = data['liked'] == true;
      final finalCount = _readInt(data['like_count'] ?? data['likeCount']);
      final settled = FeedPostModel(
        id: before.id,
        authorId: before.authorId,
        content: before.content,
        type: before.type,
        likeCount: finalCount > 0 ? finalCount : (liked ? before.likeCount + 1 : (before.likeCount > 0 ? before.likeCount - 1 : 0)),
        replyCount: before.replyCount,
        repostCount: before.repostCount,
        viewCount: before.viewCount,
        createdAt: before.createdAt,
      );
      final settledList = [...state.posts];
      final settledIndex = settledList.indexWhere((p) => p.id == postId);
      if (settledIndex != -1) {
        settledList[settledIndex] = settled;
        state = state.copyWith(posts: settledList);
      }
    } catch (error) {
      logger.error('Failed toggling like', tag: 'x-feed', error: error);
      final rollback = [...state.posts];
      final rollbackIndex = rollback.indexWhere((p) => p.id == postId);
      if (rollbackIndex != -1) {
        rollback[rollbackIndex] = before;
        state = state.copyWith(posts: rollback, errorMessage: 'Could not update like.');
      }
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.notifications));
      final rows = _extractList(res.data);
      state = state.copyWith(loading: false, notifications: rows, errorMessage: null);
    } catch (error) {
      logger.error('Failed loading feed notifications', tag: 'x-feed', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load notifications.');
    }
  }

  Future<void> loadLists() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.lists));
      final rows = _extractList(res.data);
      state = state.copyWith(loading: false, lists: rows, errorMessage: null);
    } catch (error) {
      logger.error('Failed loading feed lists', tag: 'x-feed', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load lists.');
    }
  }

  Future<void> loadTrending() async {
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.trending));
      final rows = _extractList(res.data);
      state = state.copyWith(trending: rows);
    } catch (error) {
      logger.error('Failed loading feed trending', tag: 'x-feed', error: error);
    }
  }

  Future<void> loadProfile({String? userId}) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final path = userId == null || userId.isEmpty
          ? ApiContract.feed.profile
          : ApiContract.feed.profileByUser(userId);
      final res = await ApiService.get(ApiContract.url(path));
      final map = _extractMap(res.data);
      final profileMap = _extractMap(map['data']);
      state = state.copyWith(
        loading: false,
        profile: FeedProfileModel.fromJson(profileMap),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading feed profile', tag: 'x-feed', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load profile.');
    }
  }

  Future<void> markNotificationRead(String id) async {
    final before = state.notifications;
    final optimistic = before
        .map((entry) => entry['_id']?.toString() == id ? {...entry, 'read': true} : entry)
        .toList();
    state = state.copyWith(notifications: optimistic);
    try {
      await ApiService.post(ApiContract.url(ApiContract.feed.notificationRead(id)));
    } catch (error) {
      logger.error('Failed marking notification as read', tag: 'x-feed', error: error);
      state = state.copyWith(notifications: before, errorMessage: 'Could not update notification.');
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final xFeedProvider = NotifierProvider<XFeedNotifier, XFeedState>(XFeedNotifier.new);

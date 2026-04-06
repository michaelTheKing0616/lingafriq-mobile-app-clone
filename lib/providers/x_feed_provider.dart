import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/feed_post_model.dart';
import 'package:lingafriq/models/feed_profile_model.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

const Object _kUnset = Object();

/// Feed / notifications / lists / profile state for the X-style module.
///
/// Loading flags are **split** so opening notifications does not flip timeline spinners.
/// Use [copyWith] — pass [_kUnset] for fields that should not change (via [identical] check).
class XFeedState {
  final bool timelineLoading;
  final bool notificationsLoading;
  final bool listsLoading;
  final bool profileLoading;
  final bool trendingLoading;

  final List<FeedPostModel> posts;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> lists;
  final List<Map<String, dynamic>> trending;
  final FeedProfileModel? profile;

  final String? timelineError;
  final String? notificationsError;
  final String? listsError;
  final String? profileError;

  const XFeedState({
    required this.timelineLoading,
    required this.notificationsLoading,
    required this.listsLoading,
    required this.profileLoading,
    required this.trendingLoading,
    required this.posts,
    required this.notifications,
    required this.lists,
    required this.trending,
    this.profile,
    this.timelineError,
    this.notificationsError,
    this.listsError,
    this.profileError,
  });

  factory XFeedState.initial() => const XFeedState(
        timelineLoading: false,
        notificationsLoading: false,
        listsLoading: false,
        profileLoading: false,
        trendingLoading: false,
        posts: [],
        notifications: [],
        lists: [],
        trending: [],
        profile: null,
        timelineError: null,
        notificationsError: null,
        listsError: null,
        profileError: null,
      );

  XFeedState copyWith({
    bool? timelineLoading,
    bool? notificationsLoading,
    bool? listsLoading,
    bool? profileLoading,
    bool? trendingLoading,
    List<FeedPostModel>? posts,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? lists,
    List<Map<String, dynamic>>? trending,
    FeedProfileModel? profile,
    Object? timelineError = _kUnset,
    Object? notificationsError = _kUnset,
    Object? listsError = _kUnset,
    Object? profileError = _kUnset,
  }) {
    String? pickStr(Object? v, String? current) {
      if (identical(v, _kUnset)) return current;
      return v as String?;
    }

    return XFeedState(
      timelineLoading: timelineLoading ?? this.timelineLoading,
      notificationsLoading: notificationsLoading ?? this.notificationsLoading,
      listsLoading: listsLoading ?? this.listsLoading,
      profileLoading: profileLoading ?? this.profileLoading,
      trendingLoading: trendingLoading ?? this.trendingLoading,
      posts: posts ?? this.posts,
      notifications: notifications ?? this.notifications,
      lists: lists ?? this.lists,
      trending: trending ?? this.trending,
      profile: profile ?? this.profile,
      timelineError: pickStr(timelineError, this.timelineError),
      notificationsError: pickStr(notificationsError, this.notificationsError),
      listsError: pickStr(listsError, this.listsError),
      profileError: pickStr(profileError, this.profileError),
    );
  }
}

class XFeedNotifier extends Notifier<XFeedState> {
  @override
  XFeedState build() => XFeedState.initial();

  /// Loads the main feed. When [languageCode] is set, the backend uses `mode: language`
  /// and filters by `language_code`. Otherwise [mode] is sent (`for_you`, `following`, etc.).
  Future<void> loadTimeline({String mode = 'for_you', String? languageCode}) async {
    state = state.copyWith(timelineLoading: true, timelineError: null);
    final lang = languageCode?.trim();
    final effectiveMode = (lang != null && lang.isNotEmpty) ? 'language' : mode;
    try {
      final response = await ApiService.get(
        ApiContract.url(ApiContract.feed.posts),
        queryParameters: {
          'mode': effectiveMode,
          'limit': 30,
          if (lang != null && lang.isNotEmpty) 'languageCode': lang,
        },
      );
      final rows = _extractList(response.data);
      state = state.copyWith(
        timelineLoading: false,
        posts: rows.map((row) => FeedPostModel.fromJson(row)).toList(),
        timelineError: null,
      );
    } catch (error) {
      logger.error('Failed loading X feed timeline', tag: 'x-feed', error: error);
      state = state.copyWith(
        timelineLoading: false,
        timelineError: 'Could not load your timeline.',
      );
    }
  }

  Future<bool> composePost({
    required String content,
    String type = 'text',
    String visibility = 'public',
    String? languageCode,
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
      languageCode: languageCode,
    );
    state = state.copyWith(posts: [optimistic, ...state.posts], timelineError: null);
    try {
      final response = await ApiService.post(
        ApiContract.url(ApiContract.feed.posts),
        data: {
          'content': content,
          'type': type,
          'visibility': visibility,
          if (languageCode != null && languageCode.trim().isNotEmpty)
            'language_code': languageCode.trim(),
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
        timelineError: 'Could not publish your post.',
      );
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final before = state.posts[index];
    final optimistic = before.copyWith(likeCount: before.likeCount + 1);
    final updatedList = [...state.posts];
    updatedList[index] = optimistic;
    state = state.copyWith(posts: updatedList);

    try {
      final response = await ApiService.post(ApiContract.url(ApiContract.feed.postLike(postId)));
      final payload = _extractMap(response.data);
      final data = _extractMap(payload['data']);
      final liked = data['liked'] == true;
      final finalCount = _readInt(data['like_count'] ?? data['likeCount']);
      final settled = before.copyWith(
        likeCount: finalCount > 0
            ? finalCount
            : (liked ? before.likeCount + 1 : (before.likeCount > 0 ? before.likeCount - 1 : 0)),
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
        state = state.copyWith(
          posts: rollback,
          timelineError: 'Could not update like.',
        );
      }
    }
  }

  Future<void> toggleRepost(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final before = state.posts[index];
    final optimistic = before.copyWith(repostCount: before.repostCount + 1);
    final updatedList = [...state.posts];
    updatedList[index] = optimistic;
    state = state.copyWith(posts: updatedList);

    try {
      final response = await ApiService.post(ApiContract.url(ApiContract.feed.postRepost(postId)));
      final payload = _extractMap(response.data);
      final data = _extractMap(payload['data']);
      final reposted = data['reposted'] == true;
      final finalCount = _readInt(data['repostCount'] ?? data['repost_count']);
      final settled = before.copyWith(
        repostCount: finalCount > 0
            ? finalCount
            : (reposted ? before.repostCount + 1 : (before.repostCount > 0 ? before.repostCount - 1 : 0)),
      );
      final settledList = [...state.posts];
      final settledIndex = settledList.indexWhere((p) => p.id == postId);
      if (settledIndex != -1) {
        settledList[settledIndex] = settled;
        state = state.copyWith(posts: settledList);
      }
    } catch (error) {
      logger.error('Failed toggling repost', tag: 'x-feed', error: error);
      final rollback = [...state.posts];
      final rollbackIndex = rollback.indexWhere((p) => p.id == postId);
      if (rollbackIndex != -1) {
        rollback[rollbackIndex] = before;
        state = state.copyWith(
          posts: rollback,
          timelineError: 'Could not update repost.',
        );
      }
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(notificationsLoading: true, notificationsError: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.notifications));
      final rows = _extractList(res.data);
      state = state.copyWith(
        notificationsLoading: false,
        notifications: rows,
        notificationsError: null,
      );
    } catch (error) {
      logger.error('Failed loading feed notifications', tag: 'x-feed', error: error);
      state = state.copyWith(
        notificationsLoading: false,
        notificationsError: 'Could not load notifications.',
      );
    }
  }

  Future<void> loadLists() async {
    state = state.copyWith(listsLoading: true, listsError: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.lists));
      final rows = _extractList(res.data);
      state = state.copyWith(
        listsLoading: false,
        lists: rows,
        listsError: null,
      );
    } catch (error) {
      logger.error('Failed loading feed lists', tag: 'x-feed', error: error);
      state = state.copyWith(
        listsLoading: false,
        listsError: 'Could not load lists.',
      );
    }
  }

  Future<void> loadTrending() async {
    state = state.copyWith(trendingLoading: true);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.feed.trending));
      final rows = _extractList(res.data);
      state = state.copyWith(trendingLoading: false, trending: rows);
    } catch (error) {
      logger.error('Failed loading feed trending', tag: 'x-feed', error: error);
      state = state.copyWith(trendingLoading: false);
    }
  }

  Future<void> loadProfile({String? userId}) async {
    state = state.copyWith(profileLoading: true, profileError: null);
    try {
      final path = userId == null || userId.isEmpty
          ? ApiContract.feed.profile
          : ApiContract.feed.profileByUser(userId);
      final res = await ApiService.get(ApiContract.url(path));
      final map = _extractMap(res.data);
      final profileMap = _extractMap(map['data']);
      state = state.copyWith(
        profileLoading: false,
        profile: FeedProfileModel.fromJson(profileMap),
        profileError: null,
      );
    } catch (error) {
      logger.error('Failed loading feed profile', tag: 'x-feed', error: error);
      state = state.copyWith(
        profileLoading: false,
        profileError: 'Could not load profile.',
      );
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
      state = state.copyWith(
        notifications: before,
        notificationsError: 'Could not update notification.',
      );
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

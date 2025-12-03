import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../logging/app_logger.dart';
import '../../error/error_codes.dart';
import '../../exceptions/app_exceptions.dart';

/// Comprehensive Supabase service for all backend operations
class SupabaseService {
  static final AppLogger _logger = AppLogger('SupabaseService');
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      if (!AppConfig.hasSupabaseConfig) {
        _logger.warning('Supabase configuration not found');
        return;
      }

      _logger.info('Initializing Supabase');

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: AppConfig.enableDebugLogs,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      _client = Supabase.instance.client;
      _logger.info('Supabase initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      throw NetworkException(
        message: 'Failed to initialize Supabase',
        code: ErrorCode.networkConnectionError.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw NetworkException(
        message: 'Supabase not initialized',
        code: ErrorCode.networkConnectionError.code,
      );
    }
    return _client!;
  }

  // ======================
  // AUTHENTICATION
  // ======================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('Signing up user', data: {'email': email});

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      _logger.info('User signed up successfully');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Sign up failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Signing in user', data: {'email': email});

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _logger.info('User signed in successfully');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Sign in failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _logger.info('Signing out user');
      await client.auth.signOut();
      _logger.info('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.error('Sign out failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ======================
  // DATABASE OPERATIONS
  // ======================

  /// Generic query method
  Future<List<Map<String, dynamic>>> query({
    required String table,
    Map<String, dynamic>? filters,
    List<String>? select,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      _logger.debug('Querying table', data: {'table': table});

      var query = client.from(table).select(select?.join(',') ?? '*');

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      _logger.error('Query failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Insert record
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.debug('Inserting into table', data: {'table': table});

      final response = await client.from(table).insert(data).select().single();

      _logger.debug('Insert successful');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Insert failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update record
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      _logger.debug('Updating table', data: {'table': table});

      var query = client.from(table).update(data);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select().single();

      _logger.debug('Update successful');
      return response;
    } catch (e, stackTrace) {
      _logger.error('Update failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete record
  Future<void> delete({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      _logger.debug('Deleting from table', data: {'table': table});

      var query = client.from(table).delete();

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;

      _logger.debug('Delete successful');
    } catch (e, stackTrace) {
      _logger.error('Delete failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ======================
  // STORAGE OPERATIONS
  // ======================

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file, // File or Uint8List
    Map<String, String>? metadata,
  }) async {
    try {
      _logger.info('Uploading file', data: {'bucket': bucket, 'path': path});

      await client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(
              upsert: true,
              metadata: metadata,
            ),
          );

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);

      _logger.info('File uploaded successfully');
      return publicUrl;
    } catch (e, stackTrace) {
      _logger.error('File upload failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Download file from storage
  Future<List<int>> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      _logger.info('Downloading file', data: {'bucket': bucket, 'path': path});

      final bytes = await client.storage.from(bucket).download(path);

      _logger.info('File downloaded successfully');
      return bytes;
    } catch (e, stackTrace) {
      _logger.error('File download failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      _logger.info('Deleting file', data: {'bucket': bucket, 'path': path});

      await client.storage.from(bucket).remove([path]);

      _logger.info('File deleted successfully');
    } catch (e, stackTrace) {
      _logger.error('File deletion failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get public URL for file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Create signed URL for private file
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600, // 1 hour default
  }) async {
    try {
      final url = await client.storage.from(bucket).createSignedUrl(
            path,
            expiresIn,
          );

      return url;
    } catch (e, stackTrace) {
      _logger.error('Failed to create signed URL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ======================
  // REALTIME SUBSCRIPTIONS
  // ======================

  /// Subscribe to table changes
  RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeFilter? filter,
  }) {
    _logger.info('Subscribing to table', data: {'table': table});

    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: filter,
          callback: callback,
        )
        .subscribe();
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    _logger.info('Unsubscribing from channel');
    await channel.unsubscribe();
  }

  // ======================
  // PDF-SPECIFIC OPERATIONS
  // ======================

  /// Upload PDF file
  Future<String> uploadPdf({
    required String fileName,
    required dynamic file,
    required String userId,
  }) async {
    final path = '$userId/$fileName';
    return uploadFile(
      bucket: AppConfig.supabasePdfBucket,
      path: path,
      file: file,
      metadata: {
        'userId': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Save PDF metadata to database
  Future<Map<String, dynamic>> savePdfMetadata({
    required String fileName,
    required String filePath,
    required String userId,
    int? pageCount,
    int? fileSize,
    Map<String, dynamic>? additionalData,
  }) async {
    return insert(
      table: 'pdfs',
      data: {
        'file_name': fileName,
        'file_path': filePath,
        'user_id': userId,
        'page_count': pageCount,
        'file_size': fileSize,
        'created_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      },
    );
  }

  /// Get user's PDFs
  Future<List<Map<String, dynamic>>> getUserPdfs(String userId) async {
    return query(
      table: 'pdfs',
      filters: {'user_id': userId},
      orderBy: 'created_at',
      ascending: false,
    );
  }
}

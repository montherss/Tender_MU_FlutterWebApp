import '../../../../core/network/api_client.dart';
import '../../domain/chat_domain.dart';
import '../datasource/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remoteDataSource);

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<String> sendMessage(String message) async {
    try {
      return await _remoteDataSource.sendMessage(message.trim());
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapDioException(error);
    }
  }
}

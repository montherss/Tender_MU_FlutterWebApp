import 'package:universal_html/html.dart' as html;

class AuthTokenStore {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userNameKey = 'auth_username';

  String? get token {
    final value = html.window.localStorage[_tokenKey]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get role {
    final value = html.window.localStorage[_roleKey]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get userName {
    final value = html.window.localStorage[_userNameKey]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get hasToken => token != null;

  Future<void> saveToken(String token) async {
    html.window.localStorage[_tokenKey] = token;
  }

  Future<void> saveRole(String role) async {
    html.window.localStorage[_roleKey] = role;
  }

  Future<void> saveUserName(String userName) async {
    html.window.localStorage[_userNameKey] = userName;
  }

  Future<void> clearToken() async {
    html.window.localStorage.remove(_tokenKey);
    html.window.localStorage.remove(_roleKey);
    html.window.localStorage.remove(_userNameKey);
  }
}

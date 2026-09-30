import 'dart:async';

import 'package:api/api.dart' show WebtritApiClient;

import 'package:webtrit_phone/common/disposable.dart';
import 'package:webtrit_phone/mappers/api/user_info_mapper.dart';
import 'package:webtrit_phone/models/models.dart';

abstract interface class UserRemoteDatasource implements Disposable {
  Future<UserInfo> getInfo();

  Future<void> delete();
}

class UserRemoteDatasourceApiImpl with UserInfoApiMapper implements UserRemoteDatasource {
  UserRemoteDatasourceApiImpl(this._webtritApiClient, this._token);

  final WebtritApiClient _webtritApiClient;
  final String _token;

  @override
  Future<UserInfo> getInfo() async {
    final apiUserInfo = await _webtritApiClient.getUserInfo(_token);
    return userInfoFromApi(apiUserInfo);
  }

  @override
  Future<void> delete() async {
    await _webtritApiClient.deleteUserInfo(_token);
  }

  @override
  Future<void> dispose() async {}
}

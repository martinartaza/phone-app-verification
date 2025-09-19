import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/network.dart';
import '../utils/server_error_handler.dart';

class InvitationsService {
  Future<({NetworkData networkData, FulbitosData fulbitosData})> fetchAllData(String token) async {
    final url = Uri.parse(ApiConfig.invitationsUrl);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    // Verificar si hay errores del servidor
    if (ServerErrorHandler.isServerError(response) || 
        ServerErrorHandler.isServerDown(response) || 
        ServerErrorHandler.isMaintenanceMode(response)) {
      throw Exception('MAINTENANCE_MODE');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load data: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      return (
        networkData: NetworkData(network: const [], invitationPending: const []),
        fulbitosData: FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const [])
      );
    }

    final networkSection = data['network'] as Map<String, dynamic>? ?? {};
    final fulbitosSection = data['fulbitos'] as Map<String, dynamic>? ?? {};

    String? mapPhoto(dynamic urlPhoto) {
      if (urlPhoto == null) return null;
      final path = urlPhoto.toString();
      if (path.isEmpty) return null;
      return path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    }

    List<NetworkUser> mapNetworkList(List<dynamic> list) {
      return list.map((e) {
        return NetworkUser(
          username: e['username'] ?? '',
          uuid: e['uuid'] ?? '',
          phone: e['phone'] ?? '',
          photoUrl: mapPhoto(e['url_photo']),
          invitationId: e['invitation_id'] ?? 0,
          invitationMessage: e['invitation_message'],
        );
      }).toList();
    }

    final networkList = mapNetworkList((networkSection['network'] as List<dynamic>? ) ?? const []);
    final pendingList = mapNetworkList((networkSection['invitation_pending'] as List<dynamic>? ) ?? const []);

    final networkData = NetworkData(network: networkList, invitationPending: pendingList);
    final fulbitosData = _parseFulbitos(fulbitosSection);

    return (networkData: networkData, fulbitosData: fulbitosData);
  }

  FulbitosData _parseFulbitos(Map<String, dynamic> fulbitosSection) {
    String? mapPhoto(dynamic urlPhoto) {
      if (urlPhoto == null) return null;
      final path = urlPhoto.toString();
      if (path.isEmpty) return null;
      return path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    }

    List<Fulbito> mapFulbitosList(List<dynamic> list) {
      return list.map((e) {
        return Fulbito(
          id: e['id'] ?? 0,
          name: e['name'] ?? '',
          place: e['place'] ?? '',
          day: e['day'] ?? '',
          hour: e['hour'] ?? '',
          registrationStartDay: e['registration_start_day'] ?? '',
          registrationStartHour: e['registration_start_hour'] ?? '',
          ownerName: e['owner_name'] ?? '',
          ownerPhone: e['owner_phone'] ?? '',
          ownerPhotoUrl: mapPhoto(e['owner_photo']),
          invitationId: e['invitation_id'],
          capacity: e['capacity'] ?? 10,
          message: e['message'],
          createdAt: e['created_at'] ?? '',
          updatedAt: e['updated_at'] ?? '',
          registrationStatus: e['registration_status'] != null 
              ? RegistrationStatus.fromJson(e['registration_status'] as Map<String, dynamic>)
              : null,
        );
      }).toList();
    }

    final myFulbitos = mapFulbitosList((fulbitosSection['my_fulbitos'] as List<dynamic>?) ?? const []);
    final acceptFulbitos = mapFulbitosList((fulbitosSection['accept_fulbitos'] as List<dynamic>?) ?? const []);
    final pendingFulbitos = mapFulbitosList((fulbitosSection['pending_fulbitos'] as List<dynamic>?) ?? const []);

    return FulbitosData(
      myFulbitos: myFulbitos,
      acceptFulbitos: acceptFulbitos,
      pendingFulbitos: pendingFulbitos,
    );
  }
}


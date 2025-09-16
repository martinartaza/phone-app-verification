import 'package:flutter/material.dart';
import '../models/network.dart';
import '../services/invitations.dart';

class InvitationsProvider with ChangeNotifier {
  final InvitationsService _service = InvitationsService();

  bool _isLoading = false;
  String? _error;
  NetworkData _networkData = NetworkData(network: const [], invitationPending: const []);
  FulbitosData _fulbitosData = FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const []);

  bool get isLoading => _isLoading;
  String? get error => _error;
  NetworkData get networkData => _networkData;
  FulbitosData get fulbitosData => _fulbitosData;

  bool get isNetworkEmpty => _networkData.network.isEmpty && _networkData.invitationPending.isEmpty;
  bool get isFulbitosEmpty => _fulbitosData.isEmpty;

  Future<void> load(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.fetchAllData(token);
      _networkData = data.networkData;
      _fulbitosData = data.fulbitosData;
    } catch (e) {
      _error = 'Error al cargar datos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


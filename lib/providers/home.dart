import 'package:flutter/material.dart';
import '../models/network.dart';

class HomeProvider with ChangeNotifier {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Getters
  TextEditingController get searchController => _searchController;
  String get searchQuery => _searchQuery;

  HomeProvider() {
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    _searchController.clear();
  }

  // Métodos de filtrado para fulbitos
  List<Fulbito> filterFulbitos(List<Fulbito> fulbitos) {
    if (_searchQuery.isEmpty) return fulbitos;
    
    return fulbitos.where((fulbito) {
      return fulbito.name.toLowerCase().contains(_searchQuery) ||
             fulbito.place.toLowerCase().contains(_searchQuery) ||
             fulbito.day.toLowerCase().contains(_searchQuery) ||
             fulbito.hour.toLowerCase().contains(_searchQuery) ||
             fulbito.ownerName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Métodos de filtrado para usuarios de red
  List<NetworkUser> filterNetworkUsers(List<NetworkUser> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) ||
             user.phone.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Verificar si hay resultados de búsqueda para fulbitos
  bool hasFulbitosResults({
    required List<Fulbito> pendingFulbitos,
    required List<Fulbito> myFulbitos,
    required List<Fulbito> acceptFulbitos,
  }) {
    if (_searchQuery.isEmpty) return true;
    
    final filteredPending = filterFulbitos(pendingFulbitos);
    final filteredMy = filterFulbitos(myFulbitos);
    final filteredAccept = filterFulbitos(acceptFulbitos);
    
    return filteredPending.isNotEmpty || 
           filteredMy.isNotEmpty || 
           filteredAccept.isNotEmpty;
  }

  // Verificar si hay resultados de búsqueda para usuarios
  bool hasUsersResults({
    required List<NetworkUser> invitationPending,
    required List<NetworkUser> network,
  }) {
    if (_searchQuery.isEmpty) return true;
    
    final filteredPending = filterNetworkUsers(invitationPending);
    final filteredNetwork = filterNetworkUsers(network);
    
    return filteredPending.isNotEmpty || filteredNetwork.isNotEmpty;
  }
}

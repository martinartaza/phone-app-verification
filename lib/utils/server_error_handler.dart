import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/maintenance_modal.dart';

class ServerErrorHandler {
  static bool isServerError(http.Response response) {
    // Verificar si la respuesta es HTML en lugar de JSON
    if (response.body.trim().startsWith('<!DOCTYPE') || 
        response.body.trim().startsWith('<html') ||
        response.body.trim().startsWith('<!doctype')) {
      return true;
    }
    
    // Verificar si el content-type es HTML
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html')) {
      return true;
    }
    
    return false;
  }
  
  static bool isServerDown(http.Response response) {
    // Verificar códigos de error del servidor
    return response.statusCode >= 500 && response.statusCode < 600;
  }
  
  static bool isMaintenanceMode(http.Response response) {
    // Verificar si el servidor está en modo mantenimiento
    return response.statusCode == 503 || 
           response.body.toLowerCase().contains('maintenance') ||
           response.body.toLowerCase().contains('mantenimiento');
  }
  
  static void handleServerError(BuildContext context, http.Response response, {VoidCallback? onRetry}) {
    if (isServerError(response) || isServerDown(response) || isMaintenanceMode(response)) {
      MaintenanceModal.show(context, onRetry: onRetry);
    }
  }
  
  static void handleConnectionError(BuildContext context, {VoidCallback? onRetry}) {
    MaintenanceModal.show(context, onRetry: onRetry);
  }
}

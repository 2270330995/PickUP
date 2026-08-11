import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'contact_dtos.dart';

class ContactApi {
  ContactApi(this._dio);
  final Dio _dio;

  Future<List<ContactResponse>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/contacts');
      final envelope = ApiResponse<List<ContactResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(ContactResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ContactResponse> get(String id) =>
      _contactCall(() => _dio.get<Map<String, dynamic>>('/contacts/$id'));

  Future<ContactResponse> create(CreateContactRequest req) =>
      _contactCall(() => _dio.post<Map<String, dynamic>>('/contacts', data: req.toJson()));

  Future<ContactResponse> update(String id, UpdateContactRequest req) =>
      _contactCall(() => _dio.patch<Map<String, dynamic>>('/contacts/$id', data: req.toJson()));

  Future<void> archive(String id) async {
    try {
      await _dio.delete<dynamic>('/contacts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ContactVehicleResponse>> listVehicles(String contactId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/contacts/$contactId/vehicles');
      final envelope = ApiResponse<List<ContactVehicleResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(ContactVehicleResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ContactVehicleResponse> createVehicle(String contactId, CreateContactVehicleRequest req) =>
      _vehicleCall(() =>
          _dio.post<Map<String, dynamic>>('/contacts/$contactId/vehicles', data: req.toJson()));

  Future<ContactVehicleResponse> updateVehicle(
          String contactId, String vehicleId, UpdateContactVehicleRequest req) =>
      _vehicleCall(() => _dio.patch<Map<String, dynamic>>(
          '/contacts/$contactId/vehicles/$vehicleId', data: req.toJson()));

  Future<void> deleteVehicle(String contactId, String vehicleId) async {
    try {
      await _dio.delete<dynamic>('/contacts/$contactId/vehicles/$vehicleId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ContactResponse> _contactCall(Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      final res = await call();
      final envelope = ApiResponse<ContactResponse>.fromJson(
        res.data!,
        (raw) => ContactResponse.fromJson(raw as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (data == null) {
        throw ApiException(
          statusCode: res.statusCode,
          code: 'EMPTY_RESPONSE',
          message: 'Server returned empty payload',
        );
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ContactVehicleResponse> _vehicleCall(
      Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      final res = await call();
      final envelope = ApiResponse<ContactVehicleResponse>.fromJson(
        res.data!,
        (raw) => ContactVehicleResponse.fromJson(raw as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (data == null) {
        throw ApiException(
          statusCode: res.statusCode,
          code: 'EMPTY_RESPONSE',
          message: 'Server returned empty payload',
        );
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final contactApiProvider = Provider<ContactApi>((ref) {
  return ContactApi(ref.watch(dioProvider));
});

/// The organizer's People roster (active contacts only).
final contactsProvider = FutureProvider.autoDispose<List<ContactResponse>>((ref) {
  return ref.watch(contactApiProvider).list();
});

/// Single contact detail (auto-refreshes on invalidate).
final contactDetailProvider =
    FutureProvider.autoDispose.family<ContactResponse, String>((ref, id) {
  return ref.watch(contactApiProvider).get(id);
});

/// Vehicles reusable for a given contact.
final contactVehiclesProvider =
    FutureProvider.autoDispose.family<List<ContactVehicleResponse>, String>((ref, contactId) {
  return ref.watch(contactApiProvider).listVehicles(contactId);
});

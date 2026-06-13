import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/company_provider.dart';
import '../../../core/providers/tenant_provider.dart';

class CompanyProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  CompanyProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  CompanyProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return CompanyProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class CompanyProfileNotifier extends StateNotifier<CompanyProfileState> {
  final Ref _ref;

  CompanyProfileNotifier(this._ref) : super(CompanyProfileState());

  /// Update textual company information
  Future<bool> updateCompanyDetails({
    required String name,
    required String address,
    required String phone,
    required String email,
    required String gstNumber,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final companyId = _ref.read(companyIdProvider);
      if (companyId.isEmpty) {
        throw Exception('No active company selected.');
      }

      final companyRepo = _ref.read(companyRepositoryProvider);
      final existingCompany = await companyRepo.getCompany(companyId);

      if (existingCompany == null) {
        throw Exception('Company not found.');
      }

      final updatedCompany = existingCompany.copyWith(
        name: name,
        address: address,
        phone: phone,
        email: email,
        gstNumber: gstNumber,
        updatedAt: DateTime.now(),
      );

      await companyRepo.updateCompany(updatedCompany);
      
      // Invalidate the tenant providers to trigger live UI updates
      _ref.invalidate(tenantContextProvider);
      _ref.invalidate(tenantCompanyStreamProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Validates and uploads a selected logo image
  Future<bool> uploadCompanyLogo(XFile file) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      // 1. Verify File Type
      final name = file.name.toLowerCase();
      if (!name.endsWith('.png') && !name.endsWith('.jpg') && !name.endsWith('.jpeg')) {
        throw Exception('Only PNG, JPG, and JPEG logo formats are supported.');
      }

      // 2. Verify File Size (< 2 MB)
      final length = await file.length();
      if (length > 2 * 1024 * 1024) {
        throw Exception('Logo image size must be less than 2 MB.');
      }

      final companyId = _ref.read(companyIdProvider);
      if (companyId.isEmpty) {
        throw Exception('No active company selected.');
      }

      final companyRepo = _ref.read(companyRepositoryProvider);
      final logoFile = File(file.path);

      await companyRepo.uploadLogo(companyId, logoFile);

      // Invalidate target stream to push logo updates to drawer/screens
      _ref.invalidate(tenantContextProvider);
      _ref.invalidate(tenantCompanyStreamProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Delete the company logo from storage and company document
  Future<bool> deleteCompanyLogo() async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final companyId = _ref.read(companyIdProvider);
      if (companyId.isEmpty) {
        throw Exception('No active company selected.');
      }

      final companyRepo = _ref.read(companyRepositoryProvider);
      await companyRepo.deleteLogo(companyId);

      _ref.invalidate(tenantContextProvider);
      _ref.invalidate(tenantCompanyStreamProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final companyProfileNotifierProvider =
    StateNotifierProvider.autoDispose<CompanyProfileNotifier, CompanyProfileState>((ref) {
  return CompanyProfileNotifier(ref);
});

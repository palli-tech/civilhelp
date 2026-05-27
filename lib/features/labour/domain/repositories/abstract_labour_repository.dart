import 'package:civilhelp/features/labour/data/models/labour_model.dart';

abstract class AbstractLabourRepository {
  Future<LabourModel> createLabour({
    required String fullName,
    required String phoneNumber,
    required String aadhaarNumber,
    required double dailyWage,
    required String assignedSiteId,
    required String assignedSiteName,
    required DateTime joinedDate,
    required String status,
    required String companyId,
    required String createdBy,
  });

  Future<void> updateLabour({
    required String labourId,
    required String fullName,
    required String phoneNumber,
    required String aadhaarNumber,
    required double dailyWage,
    required String assignedSiteId,
    required String assignedSiteName,
    required DateTime joinedDate,
    required String status,
  });

  Future<void> updateLabourStatus({
    required String labourId,
    required String status,
  });

  Stream<List<LabourModel>> getLabourByCompanyStream(String companyId);

  Stream<List<LabourModel>> getLabourBySiteStream(String siteId);

  Stream<List<LabourModel>> getLabourByStatusStream(String companyId, String status);

  Future<List<LabourModel>> searchLabourByName(String companyId, String searchTerm);

  Future<LabourModel?> getLabourById(String labourId);

  Future<void> deleteLabour(String labourId);
}
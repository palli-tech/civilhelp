class FirestorePathService {
  /// Returns the base path for a company
  static String company(String companyId) => 'companies/$companyId';

  /// Returns the path for the labour collection for a specific company
  static String labour(String companyId) => '${company(companyId)}/labour';

  /// Returns the path for the attendance collection for a specific company
  static String attendance(String companyId) => '${company(companyId)}/attendance';

  /// Returns the path for the payments collection for a specific company
  static String payments(String companyId) => '${company(companyId)}/payments';

  /// Returns the path for the advances collection for a specific company
  static String advances(String companyId) => '${company(companyId)}/advances';

  /// Returns the path for the sites collection for a specific company
  static String sites(String companyId) => '${company(companyId)}/sites';

  /// Returns the path for the expenses collection for a specific company
  static String expenses(String companyId) => '${company(companyId)}/expenses';
  
  /// Returns the storage path for a company's logo
  static String companyLogo(String companyId) => '${company(companyId)}/branding/logo';
}

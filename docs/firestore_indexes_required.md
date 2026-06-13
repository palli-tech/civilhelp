# Firestore Indexes Required

This document summarizes Firestore queries found in repositories and services and the composite indexes required for the current app.

## Index summary

### labour collection

1. `getLabourByCompanyStream`
   - collection: `labour`
   - where: `companyId == companyId`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `createdAt DESC`

2. `getLabourBySiteStream`
   - collection: `labour`
   - where: `assignedSiteId == siteId`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `assignedSiteId ASC`, `createdAt DESC`

3. `getLabourByStatusStream`
   - collection: `labour`
   - where: `companyId == companyId`, `status == status`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `status ASC`, `createdAt DESC`

4. `searchLabourByName`
   - collection: `labour`
   - where: `companyId == companyId`
   - orderBy: `fullName ASC`
   - range: `startAt([searchTerm])`, `endAt([searchTerm\uf8ff])`
   - required composite index:
     - `companyId ASC`, `fullName ASC`

### sites collection

1. `getSitesByCompanyStream`
   - collection: `sites`
   - where: `companyId == companyId`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `createdAt DESC`

### attendance collection

1. `getAttendanceByCompanyStream`
   - collection: `attendance`
   - where: `companyId == companyId`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `date DESC`

2. `getAttendanceBySiteStream`
   - collection: `attendance`
   - where: `companyId == companyId`, `siteId == siteId`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `siteId ASC`, `date DESC`

3. `getAttendanceByLabourStream`
   - collection: `attendance`
   - where: `companyId == companyId`, `labourId == labourId`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `labourId ASC`, `date DESC`

4. `getAttendanceByDateRangeStream`
   - collection: `attendance`
   - where: `companyId == companyId`, `date >= start`, `date < end`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `date DESC`

### payments collection

1. `getPaymentsByCompanyStream`
   - collection: `payments`
   - where: `companyId == companyId`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `createdAt DESC`

2. `getPaymentsByStatusStream`
   - collection: `payments`
   - where: `companyId == companyId`, `status == status`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `status ASC`, `createdAt DESC`

3. `calculatePaymentSummaryForPeriod` attendance query
   - collection: `attendance` (subcollection path: `companies/{companyId}/attendance`)
   - where: `labourId == labourId`, `siteId == siteId`, `date >= periodStart`, `date <= periodEnd`
   - orderBy: implicit on `date`
   - required composite index:
     - `labourId ASC`, `siteId ASC`, `date ASC`

4. `calculatePaymentSummaryForPeriod` advances query
   - collection: `advances`
   - where: `companyId == companyId`, `labourId == labourId`, `paidBack == false`
   - orderBy: none
   - required composite index:
     - `companyId ASC`, `labourId ASC`, `paidBack ASC`

5. `getPaymentsByLabourStream`
   - collection: `payments`
   - where: `companyId == companyId`, `labourId == labourId`
   - orderBy: `createdAt DESC`
   - required composite index:
     - `companyId ASC`, `labourId ASC`, `createdAt DESC`

### advances collection

1. `getAdvancesByCompanyStream`
   - collection: `advances`
   - where: `companyId == companyId`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `date DESC`

2. `getOutstandingAdvancesByCompanyStream`
   - collection: `advances`
   - where: `companyId == companyId`, `paidBack == false`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `paidBack ASC`, `date DESC`

3. `getAdvancesByLabourStream`
   - collection: `advances`
   - where: `companyId == companyId`, `labourId == labourId`
   - orderBy: `date DESC`
   - required composite index:
     - `companyId ASC`, `labourId ASC`, `date DESC`

## Notes
- Single-document reads (`collection('users').doc(user.uid).get()`) do not require composite indexes.
- Document writes also do not affect composite index requirements beyond Firestore default single-field indexing.
- The indexes below are the composite indexes needed by the current active query patterns.

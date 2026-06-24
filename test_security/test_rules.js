const {
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { 
  doc, 
  getDoc, 
  setDoc, 
  updateDoc, 
  collection, 
  getDocs,
  serverTimestamp,
} = require("firebase/firestore");
const {
  ref,
  deleteObject,
  uploadString
} = require("firebase/storage");
const fs = require("fs");
const path = require("path");

async function runTests() {
  console.log("=== CivilHelp Security Rules Validation Run ===");

  const firestoreRules = fs.readFileSync(path.join(__dirname, "../firestore.rules"), "utf8");
  const lines = firestoreRules.split("\n");
  console.log("DEBUG: Line 213 in test rules script is:", lines[212]);
  const storageRules = fs.readFileSync(path.join(__dirname, "../storage.rules"), "utf8");
  
  const testEnv = await initializeTestEnvironment({
    projectId: "civilhelp-prod",
    firestore: {
      rules: firestoreRules,
      host: "127.0.0.1",
      port: 8080
    },
    storage: {
      rules: storageRules,
      host: "127.0.0.1",
      port: 9199
    }
  });

  // Seed default DB state
  console.log("\nSetting up seed data with security rules disabled...");
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    
    // Seed an existing company owned by owner_uid
    await setDoc(doc(db, "companies/target_company_id"), {
      ownerUid: "owner_uid",
      name: "Target Construction Corp",
      active: true,
      isActive: true,
      attendanceBackdateLimitDays: 3
    });

    // Seed the company owner user profile
    await setDoc(doc(db, "users/owner_uid"), {
      companyId: "target_company_id",
      tenantId: "target_company_id",
      role: "owner",
      active: true,
      isActive: true,
      email: "owner@target.com",
      onboarded: true
    });

    // Seed the attacker profile as pending
    await setDoc(doc(db, "users/attacker_uid"), {
      companyId: "",
      tenantId: "",
      role: "pending",
      active: true,
      isActive: true,
      email: "attacker@gmail.com",
      onboarded: false
    });

    // Seed a site under the company
    await setDoc(doc(db, "companies/target_company_id/sites/site_a"), {
      name: "Site Alpha",
      active: true
    });

    // Seed active labour
    await setDoc(doc(db, "companies/target_company_id/labour/labour_1"), {
      name: "Labourer One",
      status: "active"
    });

    console.log("Seed data created successfully.");
  });

  // Setup contexts
  const attackerContext = testEnv.authenticatedContext("attacker_uid", { email: "attacker@gmail.com" });
  const attackerDb = attackerContext.firestore();

  // ----------------------------------------------------
  // TEST A: Pending user attempts supervisor onboarding without invitation
  // ----------------------------------------------------
  console.log("\n--- TEST A: Pending user attempts supervisor onboarding without invitation ---");
  const testAPayload = {
    role: "supervisor",
    companyId: "target_company_id",
    tenantId: "target_company_id",
    assignedSiteIds: ["site_a"],
    active: true,
    isActive: true,
    onboarded: false,
    email: "attacker@gmail.com"
  };
  console.log("Attempting to onboard attacker_uid as supervisor of target_company_id...");
  console.log("Payload:", JSON.stringify(testAPayload, null, 2));

  let testAVerdict = "FAILED (Still Vulnerable)";
  try {
    await setDoc(doc(attackerDb, "users/attacker_uid"), testAPayload);
    console.log("Result: SUCCESS (Bypass Succeeded!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testAVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST B: Pending user attempts cross-company read
  // ----------------------------------------------------
  console.log("\n--- TEST B: Pending user attempts cross-company read ---");
  console.log("Attempting to read target_company_id details as attacker_uid...");
  
  let testBVerdict = "FAILED (Still Vulnerable)";
  try {
    await getDoc(doc(attackerDb, "companies/target_company_id"));
    console.log("Result: SUCCESS (Read Allowed!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testBVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST C: Pending user attempts attendance write
  // ----------------------------------------------------
  console.log("\n--- TEST C: Pending user attempts attendance write ---");
  const testCPayload = {
    labourId: "labour_1",
    siteId: "site_a",
    date: new Date("2026-06-23T12:00:00Z"),
    isDeleted: false,
    paymentStatus: "unpaid",
    payrollPeriodId: "period_1",
    dailyWageSnapshot: 500,
    earningsSnapshot: 500,
    musterQuantity: 1
  };
  console.log("Attempting to log attendance under target_company_id as attacker_uid...");
  console.log("Payload:", JSON.stringify(testCPayload, null, 2));

  let testCVerdict = "FAILED (Still Vulnerable)";
  try {
    await setDoc(doc(attackerDb, "companies/target_company_id/attendance/labour_1_site_a_2026-06-23"), testCPayload);
    console.log("Result: SUCCESS (Write Allowed!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testCVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST D: Pending user attempts owner escalation
  // ----------------------------------------------------
  console.log("\n--- TEST D: Pending user attempts owner escalation ---");
  const testDPayload = {
    role: "owner",
    companyId: "target_company_id",
    tenantId: "target_company_id",
    active: true,
    isActive: true,
    onboarded: true,
    email: "attacker@gmail.com"
  };
  console.log("Attempting to self-escalate role to owner as attacker_uid...");
  console.log("Payload:", JSON.stringify(testDPayload, null, 2));

  let testDVerdict = "FAILED (Still Vulnerable)";
  try {
    await setDoc(doc(attackerDb, "users/attacker_uid"), testDPayload);
    console.log("Result: SUCCESS (Escalation Allowed!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testDVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST E: User attempts company creation without approved request
  // ----------------------------------------------------
  console.log("\n--- TEST E: User attempts company creation without approved request ---");
  const testEPayload = {
    ownerUid: "attacker_uid",
    name: "Unauthorized Company Inc"
  };
  console.log("Attempting to create company companies/attacker_company as attacker_uid...");
  console.log("Payload:", JSON.stringify(testEPayload, null, 2));

  let testEVerdict = "FAILED (Still Vulnerable)";
  try {
    await setDoc(doc(attackerDb, "companies/attacker_company"), testEPayload);
    console.log("Result: SUCCESS (Creation Allowed!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testEVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST F: Approved owner creates company
  // ----------------------------------------------------
  console.log("\n--- TEST F: Approved owner creates company ---");
  const approvedOwnerUid = "approved_owner_uid";
  const approvedOwnerEmail = "approved_owner@gmail.com";
  
  // Seed approved request
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `company_requests/${approvedOwnerUid}`), {
      ownerUid: approvedOwnerUid,
      companyName: "Legit Construction Co",
      status: "approved"
    });
    // Seed user doc as pending (as it would be before company creation)
    await setDoc(doc(db, `users/${approvedOwnerUid}`), {
      companyId: "",
      tenantId: "",
      role: "pending",
      active: true,
      isActive: true,
      email: approvedOwnerEmail,
      onboarded: false
    });
  });

  const approvedContext = testEnv.authenticatedContext(approvedOwnerUid, { email: approvedOwnerEmail });
  const approvedDb = approvedContext.firestore();

  // Debug check
  let docSnap;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    docSnap = await getDoc(doc(db, `company_requests/${approvedOwnerUid}`));
  });
  console.log("Debug: company_requests doc exists?", docSnap.exists(), "data:", docSnap.data());

  try {
    const userSnap = await getDoc(doc(approvedDb, `users/${approvedOwnerUid}`));
    console.log("Debug: Read own user profile success:", userSnap.exists(), userSnap.data());
  } catch (err) {
    console.log("Debug: Read own user profile failed:", err.message);
  }

  try {
    const reqSnap = await getDoc(doc(approvedDb, `company_requests/${approvedOwnerUid}`));
    console.log("Debug: Read own company request success:", reqSnap.exists(), reqSnap.data());
  } catch (err) {
    console.log("Debug: Read own company request failed:", err.message);
  }

  const testFPayload = {
    ownerUid: approvedOwnerUid,
    name: "Legit Construction Co",
    active: true,
    isActive: true
  };
  console.log("Attempting to create company companies/approved_company as approved owner...");
  console.log("Payload:", JSON.stringify(testFPayload, null, 2));

  let testFVerdict = "BLOCKED (Legitimate Workflow Broken)";
  try {
    await setDoc(doc(approvedDb, "companies/approved_company"), testFPayload);
    console.log("Result: SUCCESS (Company created successfully!)");
    testFVerdict = "ALLOWED (Legitimate Workflow Intact)";
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
  }

  // ----------------------------------------------------
  // TEST G: Valid invited supervisor accepts invitation
  // ----------------------------------------------------
  console.log("\n--- TEST G: Valid invited supervisor accepts invitation ---");
  const inviteeUid = "invitee_uid";
  const inviteeEmail = "invitee@target.com";

  // Seed pending user and invitation under company
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    // Seed user doc
    await setDoc(doc(db, `users/${inviteeUid}`), {
      companyId: "",
      tenantId: "",
      role: "pending",
      active: true,
      isActive: true,
      email: inviteeEmail,
      onboarded: false
    });
    // Seed invitation doc (with ID equal to normalized email address)
    await setDoc(doc(db, "companies/target_company_id/invitations/invitee@target.com"), {
      id: "invitee@target.com",
      companyId: "target_company_id",
      tenantId: "target_company_id",
      email: inviteeEmail,
      role: "supervisor",
      assignedSiteIds: ["site_a"],
      status: "pending",
      invitedBy: "owner_uid",
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7)
    });
  });

  const inviteeContext = testEnv.authenticatedContext(inviteeUid, { email: inviteeEmail });
  const inviteeDb = inviteeContext.firestore();

  console.log("Step G.1: Invitee transitions invitation status to 'accepted'...");
  let stepG1Success = false;
  try {
    await updateDoc(doc(inviteeDb, "companies/target_company_id/invitations/invitee@target.com"), {
      status: "accepted",
      acceptedByUid: inviteeUid,
      acceptedAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
    console.log("Result: SUCCESS (Invitation accepted!)");
    stepG1Success = true;
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
  }

  console.log("Step G.2: Invitee onboards as supervisor...");
  const inviteeOnboardPayload = {
    role: "supervisor",
    companyId: "target_company_id",
    tenantId: "target_company_id",
    assignedSiteIds: ["site_a"],
    active: true,
    isActive: true,
    onboarded: false,
    email: inviteeEmail
  };
  let stepG2Success = false;
  try {
    // In our rules, to avoid undefined lookup crash, the user doc must exist (pre-seeded above)
    // We update it to transition from pending to supervisor
    await setDoc(doc(inviteeDb, `users/${inviteeUid}`), inviteeOnboardPayload);
    console.log("Result: SUCCESS (User onboarded as supervisor!)");
    stepG2Success = true;
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
  }

  // Now, test if the new supervisor's getFormattedDate calls work without crashes!
  let dateHelperSuccess = false;
  if (stepG2Success) {
    // Debug check for User Profile and Company
    let userSnap, compSnap;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      userSnap = await getDoc(doc(db, `users/${inviteeUid}`));
      compSnap = await getDoc(doc(db, "companies/target_company_id"));
    });
    console.log("Debug G.3: User doc exists?", userSnap.exists(), "data:", userSnap.data());
    console.log("Debug G.3: Company doc exists?", compSnap.exists(), "data:", compSnap.data());

    console.log("Step G.3: Testing if valid supervisor can log attendance (proving date helper helper fixes)...");
    const legitAttPayload = {
      labourId: "labour_1",
      siteId: "site_a",
      date: new Date("2026-06-23T12:00:00Z"),
      isDeleted: false,
      paymentStatus: "unpaid",
      payrollPeriodId: "period_1",
      dailyWageSnapshot: 500,
      earningsSnapshot: 500,
      musterQuantity: 1
    };
    try {
      await setDoc(doc(inviteeDb, "companies/target_company_id/attendance/labour_1_site_a_2026-06-23"), legitAttPayload);
      console.log("Result: SUCCESS (Attendance logged successfully!)");
      dateHelperSuccess = true;
    } catch (error) {
      console.log("Result: BLOCKED (Error:", error.message, ")");
    }
  }

  let testGVerdict = (stepG1Success && stepG2Success && dateHelperSuccess) 
    ? "ALLOWED (Legitimate Onboarding and Date Helpers Work)" 
    : "BLOCKED (Legitimate Onboarding Broken)";

  // ----------------------------------------------------
  // TEST H: Supervisor attempts branding modification
  // ----------------------------------------------------
  console.log("\n--- TEST H: Supervisor attempts branding modification ---");
  const inviteeStorage = inviteeContext.storage();
  const fileRef = ref(inviteeStorage, "companies/target_company_id/branding/logo.png");

  let testHVerdict = "FAILED (Still Vulnerable)";
  try {
    await uploadString(fileRef, "fake_logo_base64", "raw");
    console.log("Result: SUCCESS (Upload Allowed!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testHVerdict = "BLOCKED (Exploit Prevented)";
  }

  // ----------------------------------------------------
  // TEST I: Owner modifies branding
  // ----------------------------------------------------
  console.log("\n--- TEST I: Owner modifies branding ---");
  const ownerContext = testEnv.authenticatedContext("owner_uid", { email: "owner@target.com" });
  const ownerStorage = ownerContext.storage();
  const ownerFileRef = ref(ownerStorage, "companies/target_company_id/branding/logo.png");

  let testIVerdict = "BLOCKED (Legitimate Workflow Broken)";
  try {
    await uploadString(ownerFileRef, "fake_logo_base64_legit", "raw");
    console.log("Result: SUCCESS (Logo uploaded successfully!)");
    
    // Clean up
    await deleteObject(ownerFileRef);
    console.log("Result: SUCCESS (Logo deleted successfully!)");
    testIVerdict = "ALLOWED (Legitimate Workflow Intact)";
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
  }

  // ----------------------------------------------------
  // TEST J - Cross Tenant User Profile Read
  // ----------------------------------------------------
  console.log("\n--- TEST J - Cross Tenant User Profile Read ---");
  const companyAOwnerUid = "company_a_owner";
  const companyBOwnerUid = "company_b_owner";
  const companyBUserUid = "company_b_user";
  const companyASupervisorUid = "company_a_supervisor";

  // Seed data for Test J
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    
    // Seed Company A Document
    await setDoc(doc(db, "companies/company_a"), {
      ownerUid: companyAOwnerUid,
      name: "Company A",
      active: true,
      isActive: true
    });

    // Seed Company B Document
    await setDoc(doc(db, "companies/company_b"), {
      ownerUid: companyBOwnerUid,
      name: "Company B",
      active: true,
      isActive: true
    });

    // Seed Company A Owner Profile
    await setDoc(doc(db, `users/${companyAOwnerUid}`), {
      companyId: "company_a",
      tenantId: "company_a",
      role: "owner",
      active: true,
      email: "owner_a@company.com",
      onboarded: true
    });

    // Seed Company B Owner Profile
    await setDoc(doc(db, `users/${companyBOwnerUid}`), {
      companyId: "company_b",
      tenantId: "company_b",
      role: "owner",
      active: true,
      email: "owner_b@company.com",
      onboarded: true
    });

    // Seed Company B User Profile
    await setDoc(doc(db, `users/${companyBUserUid}`), {
      companyId: "company_b",
      tenantId: "company_b",
      role: "supervisor",
      active: true,
      email: "supervisor_b@company.com",
      onboarded: true
    });

    // Seed Company A Supervisor Profile
    await setDoc(doc(db, `users/${companyASupervisorUid}`), {
      companyId: "company_a",
      tenantId: "company_a",
      role: "supervisor",
      active: true,
      email: "supervisor_a@company.com",
      onboarded: true
    });
  });

  const companyAOwnerContext = testEnv.authenticatedContext(companyAOwnerUid, { email: "owner_a@company.com" });
  const companyAOwnerDb = companyAOwnerContext.firestore();

  let testJPart1Success = false; // Expected: BLOCKED
  let testJPart2Success = false; // Expected: ALLOWED

  console.log("Attempt J.1: Company A Owner reads Company B User Profile...");
  try {
    await getDoc(doc(companyAOwnerDb, `users/${companyBUserUid}`));
    console.log("Result: SUCCESS (Read Allowed - Tenant Isolation Violated!)");
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
    testJPart1Success = true;
  }

  console.log("Attempt J.2: Company A Owner reads Company A Supervisor Profile...");
  try {
    const docSnap = await getDoc(doc(companyAOwnerDb, `users/${companyASupervisorUid}`));
    if (docSnap.exists() && docSnap.data().companyId === "company_a") {
      console.log("Result: SUCCESS (Read Allowed - Same Tenant Access Intact)");
      testJPart2Success = true;
    } else {
      console.log("Result: FAILED (Document not found or mismatch)");
    }
  } catch (error) {
    console.log("Result: BLOCKED (Error:", error.message, ")");
  }

  let testJVerdict = (testJPart1Success && testJPart2Success)
    ? "PASS (Tenant Isolation Verified)"
    : "FAIL (Tenant Isolation Violated/Broken)";

  // Cleanup Environment
  await testEnv.cleanup();

  console.log("\n=== Remediation Validation Results ===");
  console.log(`Test A (Supervisor Self-Onboarding Bypass):   ${testAVerdict}`);
  console.log(`Test B (Cross-Company Data Read Bypass):       ${testBVerdict}`);
  console.log(`Test C (Cross-Company Attendance Write):       ${testCVerdict}`);
  console.log(`Test D (Owner Escalation Path Bypass):         ${testDVerdict}`);
  console.log(`Test E (Company Creation Request Bypass):      ${testEVerdict}`);
  console.log(`Test F (Approved Owner Company Setup):         ${testFVerdict}`);
  console.log(`Test G (Invited Supervisor Onboarding & Logs): ${testGVerdict}`);
  console.log(`Test H (Supervisor Storage Branding Write):   ${testHVerdict}`);
  console.log(`Test I (Owner Storage Branding Write):         ${testIVerdict}`);
  console.log(`Test J (Cross Tenant User Profile Read):       ${testJVerdict}`);
}

runTests().catch(console.error);

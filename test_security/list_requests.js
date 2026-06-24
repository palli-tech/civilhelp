const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");
const { getDocs, collection } = require("firebase/firestore");

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: "civilhelp-prod",
    firestore: {
      host: "127.0.0.1",
      port: 8080
    }
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const snap = await getDocs(collection(db, "company_requests"));
    console.log("Documents in company_requests collection:");
    snap.forEach(doc => {
      console.log(`- ID: ${doc.id}, Data:`, doc.data());
    });
    
    const usersSnap = await getDocs(collection(db, "users"));
    console.log("Documents in users collection:");
    usersSnap.forEach(doc => {
      console.log(`- ID: ${doc.id}, Data:`, doc.data());
    });
  });

  await testEnv.cleanup();
}

main().catch(console.error);

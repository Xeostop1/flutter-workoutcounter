const functions = require("firebase-functions/v1");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

exports.deleteUserData = functions
  .region("asia-northeast3")
  .runWith({timeoutSeconds: 540, memory: "1GB"})
  .auth.user()
  .onDelete(async (user) => {
    const db = getFirestore();
    const userDocument = db.doc(`users/${user.uid}`);

    await db.recursiveDelete(userDocument);
    functions.logger.info("Deleted Firestore data for withdrawn user", {
      uid: user.uid,
    });
  });

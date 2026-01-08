import admin from 'firebase-admin';

function initFirebase() {
  if (admin.apps.length) return admin;

  // 1) Intentar inicializar con credenciales base64 si existen
  const b64 = process.env.FIREBASE_CREDENTIALS_BASE64;
  if (b64) {
    const jsonStr = Buffer.from(b64, 'base64').toString('utf8');
    const serviceAccount = JSON.parse(jsonStr);
    const projectId =
      process.env.FIREBASE_PROJECT_ID ||
      serviceAccount.project_id ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT;

    if (!projectId) {
      throw new Error(
        'Falta projectId. Define FIREBASE_PROJECT_ID o incluye project_id en el JSON de credenciales.'
      );
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
    console.log('[firebase-admin] Inicializado con credenciales base64, projectId:', projectId);
    return admin;
  }

  // 2) Usar GOOGLE_APPLICATION_CREDENTIALS o ADC
  try {
    const projectId =
      process.env.FIREBASE_PROJECT_ID ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT;

    if (!projectId) {
      throw new Error(
        'Falta projectId en entorno. Define FIREBASE_PROJECT_ID o GOOGLE_CLOUD_PROJECT/GCLOUD_PROJECT.'
      );
    }

    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
    console.log('[firebase-admin] Inicializado con ADC, projectId:', projectId);
    return admin;
  } catch (err) {
    // 3) Fallback: error explícito
    throw new Error(
      'No se pudieron cargar credenciales de Firebase Admin. ' +
        'Configura FIREBASE_CREDENTIALS_BASE64 o GOOGLE_APPLICATION_CREDENTIALS y establece FIREBASE_PROJECT_ID.'
    );
  }
}

export const firebase = initFirebase();
export const db = firebase.firestore();
export const messaging = firebase.messaging();

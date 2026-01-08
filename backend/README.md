# UniEscom Backend (Express + Firebase Admin)

Persistencia y envío de notificaciones push (FCM) para la app Flutter.

## Requisitos
- Node.js 18+
- Credenciales de servicio de Firebase (Service Account)

## Configuración
1. Copia `.env.example` a `.env` y configura al menos una de estas opciones:
	 - `GOOGLE_APPLICATION_CREDENTIALS` apuntando a tu JSON de service account
	 - `FIREBASE_CREDENTIALS_BASE64` con el contenido del JSON en base64
2. Opcional: establece `FIREBASE_PROJECT_ID` si no está en las credenciales.
3. (Primera vez) instala dependencias:

```bash
cd UniEscom/backend
npm install
```

## Ejecución

Desarrollo (watch):
```bash
npm run dev
```

Producción:
```bash
npm start
```

Healthcheck:
```bash
curl http://localhost:3001/health
```

## Endpoints

- POST `/api/notifications/send`
	- body: `{ "uids": string[], "title": string, "body": string, "data?": object, "save?": boolean }`
	- Guarda (opcional) una notificación por usuario en `notificaciones` y envía push a sus `fcm_token`.

- POST `/api/notifications`
	- body: `{ "uid": string, "title": string, "body": string, "data?": object }`
	- Solo persiste sin enviar push.

- GET `/api/notifications/:uid?limit=20&before={docId}`
	- Lista notificaciones de un usuario (paginación simple por `sentAt`).

- POST `/api/tokens`
	- body: `{ "uid": string, "token": string }`
	- Actualiza `usuarios/{uid}.fcm_token`.

## Modelo de datos
- Colección `usuarios`: documentos con campo `fcm_token` (ya gestionado por la app Flutter).
- Colección `notificaciones`: `{ uid, title, body, data, read, sentAt }`.

## Notas
- El payload `data` se envía como string en FCM; el servicio convierte valores a `string`.
- Si necesitas enviar a topics, se puede añadir un endpoint `/topics/:topic` fácilmente.
- Para auditoría avanzada, considera duplicar la notificación en `usuarios/{uid}/notificaciones` mediante Cloud Functions/trigger.
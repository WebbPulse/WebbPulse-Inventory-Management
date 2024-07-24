# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn, identity_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials, auth
import google.cloud.firestore as gcf


###NEED TO OBFUSCATE THE SERVICE ACCOUNT KEY
serviceAccountKey = {
    "type": "service_account",
    "project_id": "webbcheck",
    "private_key_id": "dc72e5778c392d030d6d994e56bc0c44691d6820",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCw1fKrrXwIHp6U\nvJMymvKRtW2Sj1UbaalsYsr1nTQIV1dwMK0fseSWqRD0QqcfmkJs6zwY0krp61N6\n0/+kvdJtMSY9BuN3V4UVcqqUgwo7fJ3f+wHtKnvVNxW0ZfPgay2yW6Dm0bZwfuQU\nX4+IVE0SGkpD2fO0ZCpq0ydPDu1dvjfL+x20CrX2kybZ7lz+j+xXqPj9AYfXd0b0\n2pOdepe3KbAmmgv0B3UEV4+3Ff2ZY/Lb8mwHXVEd999B0FTqo9eXZV6Pfz2N9tQN\ngf1gqgEaI57qq9cksH6aJZ0bLYAvFxLl2/FwmKXBxhvVd+UsIgD13Qc5GmcGaHcL\nJlREcfFNAgMBAAECggEAHZVBMmLEtegHcAsHFgdxbppbMRJM8tfPmdwCJ6pLptyT\numdOQxfjzaeNeEuBQWpxU97bkCx4D1+IuOrn4NPHtPAsvTdejNvFnhOvgUZVyyNb\nFvobNaWujzoWpbYLoT7U53poNc0eF/5GYjklXjF6Lj3bMDQxTruWFAZslE+DOrP8\n4YD00Ujuswu1tKBv9uW2kNcTTd6xO3QLZjBJCrAywuVRr8r8Oesraglc9XVIKeX1\nJ9Fo9IhlwOpyz1TtcPNUu9Rdr3Eb8mR+FvsqYxsFsbLWKZK5i5Qp6geaeDuMRz0R\nyE2aSewklAR+wUQi0nVKAMF3sjyPMGGYLwaPbp4tgQKBgQDupXtDIUA9PzIfCBR0\ntK5uCahqrMCYlN/3BuId4xz/wgLOXUI5pKw8VVRuUozaHFYGmnYf0ZTF+3RnIYCj\nJqAxCgS2md3Kr/Vvq/8cqrcJ3a7ddrdUNZiTJkc5X38/NapM2KAofPSpbC4+0ND4\ncVnp1fikZ3UbD1M+M/n1H+zrzQKBgQC9sdSrejEob0/3vdBX81q+RpXZsX/RmMep\nQo5n9sb7x/foBio5mXn6EpAcLCKAldTWZmBh8zGLz3u0v0I4meoOF7daY/lu0OVg\n9fZnQ0Nwc2om/ziXK8k5xMxbmX8QWQchy6idm7mMkT/7ATXkiZrGfcOsmt+A3YCn\nAd/KonKbgQKBgDt7dai6zfc2HDkN24NnUZ7Nu3OzUWH2oYhB5/RJGn5JDkf/iLUz\nbVawchX5b3Ah5fNJZq3xoCJk1ZOrDxQbWYw/kgMtgNG3X/aQqUqs5miIH8DFiVZs\n8XWj8dbEDcRkjOkQiYLt+lGMTE6N37g9EIsvMQVRYCf5fucfL2tApN31AoGAUn4H\nEhstTXw6tm3hMJ4vlBd2CxlZkHh0O3MqIqP6nHu1nz0vF6VamhmAef/ncSu3RxV2\nTKJJpZcxIMUbsymb000U+0YGrt5BIg1UfkuOBFTskNDkdzkfZPPkOuFhlGZi55t9\nVCzoX+y6ehloql385NzEP0eKcqvgyr/R5nkGhgECgYBPClxkmPBDZwTa+heyFn6p\nOr2wp3yF59yG6d/xUPF6DyJ4UcV+IRLh+QolljfWUWyjiO0usLnPyNal42pDax0P\nhAThuONOqJeXORdL2YR8vMV/tv3b+jlJ3VSigLQjDsQp9EN8xu2f8B0PmLZy/hca\n2unGiXWwAjfzyT+Xnr3O7w==\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-bday4@webbcheck.iam.gserviceaccount.com",
    "client_id": "110054405663411805604",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-bday4%40webbcheck.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }

allowed_domains = ["gmail.com"]

cred = credentials.Certificate(serviceAccountKey)
app = initialize_app(cred)

db = firestore.client()

@identity_fn.before_user_created()
def create_user_ui(event: identity_fn.AuthBlockingEvent) -> identity_fn.BeforeCreateResponse | None:
    user = event.data
    try:
        if not user.email or user.email.split("@")[1] not in allowed_domains:
            return https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Unauthorized email"
            )
        create_user_profile(user)
    except https_fn.HttpsError as e:
        return identity_fn.BeforeCreateResponse(
            error=identity_fn.Error(
                message=e.message,
                code=e.code
            )
        )

def create_user_profile(user) -> None:
    user_data = {
        'created_at': firestore.SERVER_TIMESTAMP,
        'email': user.email,
        'organizationUids': [],
        'uid': user.uid,
        'username': user.display_name,
    }
    db.collection('users').document(user.uid).set(user_data)

@https_fn.on_request()
def create_user_https(req: https_fn.Request) -> https_fn.Response:
    email = req.args.get("email")
    display_name = req.args.get("display_name")

    if not email or not display_name:
        return https_fn.Response("Not all parameters provided", status=400)

    if email.split("@")[1] not in allowed_domains:
        return https_fn.Response("Unauthorized email", status=403)
    try:
        user = auth.create_user(
            email=email,
            email_verified=False,
            display_name=display_name,
            disabled=False
        )
        create_user_profile(user)
        return https_fn.Response(f"User {user.uid} created", status=200)
    except Exception as e:
        return https_fn.Response(f"Error creating user: {str(e)}", status=500)

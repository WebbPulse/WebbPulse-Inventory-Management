# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, credentials


# Read the service account key from the file

cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)

from src.users.create_user_callable import create_user_callable
from src.users.create_user_ui import create_user_ui
from src.organizations.create_organization_callable import create_organization_callable







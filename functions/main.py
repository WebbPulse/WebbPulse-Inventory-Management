# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, credentials


# Read the service account key from the file

cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)

from src.users.create_user_callable import create_user_callable
from src.users.create_user_ui import create_user_ui
from src.organizations.create_organization_callable import create_organization_callable
from src.devices.create_device_callable import create_device_callable
from src.devices.update_device_checkout_status_callable import update_device_checkout_status_callable
from src.users.monitor_for_user_changes import monitor_for_user_changes
from src.users.update_global_user_display_name_callable import update_global_user_display_name_callable
from src.users.update_global_user_photo_url_callable import update_global_user_photo_url_callable
from src.users.update_user_role_callable import update_user_role_callable







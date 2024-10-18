# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, credentials


# Read the service account key from the file
cred = credentials.Certificate('./gcp_key.json')
    
app = initialize_app(cred)

#org admin callable functions
from src.callable_functions.org_admin_callables.users.create_users_callable import create_users_callable
from src.callable_functions.org_admin_callables.users.update_user_role_callable import update_user_role_callable
from src.callable_functions.org_admin_callables.organizations.update_org_background_image_callable import update_org_background_image_callable
from src.callable_functions.org_admin_callables.organizations.update_org_name_callable import update_org_name_callable
from src.callable_functions.org_admin_callables.organizations.delete_org_callable import delete_org_callable
from src.callable_functions.org_admin_callables.users.delete_org_member_callable import delete_org_member_callable
from src.callable_functions.org_admin_callables.devices.delete_device_callable import delete_device_callable

#org member callable functions
from src.callable_functions.org_member_callables.devices.create_devices_callable import create_devices_callable
from src.callable_functions.org_member_callables.devices.update_device_checkout_status_callable import update_device_checkout_status_callable

#global user callable functions
from src.callable_functions.global_user_callables.organizations.create_organization_callable import create_organization_callable
from src.callable_functions.global_user_callables.global_user_profile.update_global_user_display_name_callable import update_global_user_display_name_callable
from src.callable_functions.global_user_callables.global_user_profile.update_global_user_photo_url_callable import update_global_user_photo_url_callable
from src.callable_functions.global_user_callables.global_user_profile.create_global_user_profile_callable import create_global_user_profile_callable
from src.callable_functions.global_user_callables.global_user_profile.delete_global_user_callable import delete_global_user_callable

#firestore triggered functions
from src.firestore_triggered_functions.monitor_for_user_changes import monitor_for_user_changes








from src.shared import firestore_fn, auth
from src.helper_functions.users.update_user_display_names_in_orgs import update_user_display_names_in_orgs
from src.helper_functions.users.update_user_photo_urls_in_orgs import update_user_photo_urls_in_orgs
from firebase_functions.firestore_fn import (
  Event,
  Change,
  DocumentSnapshot,
)

@firestore_fn.on_document_updated(document="users/{userId}")
def monitor_for_user_changes(event: Event[Change[DocumentSnapshot]]) -> None:
    # Get the data from after the event
    
    uid = event.data.after.get("uid")
    user = auth.get_user(uid)
    # Extract custom claims from the user record
    custom_claims = user.custom_claims or {}

    # Filter out the organization IDs from the custom claims
    user_org_ids = [
        claim.split("_")[-1]
        for claim in custom_claims.keys()
        if claim.startswith("org_member_") or claim.startswith("org_admin_")
    ]


    user_display_name = event.data.after.get("userDisplayName")
    user_photo_url = event.data.after.get("userPhotoURL")
    # Update the user display name in all organizations
    for user_org_id in user_org_ids:
      update_user_display_names_in_orgs(user_org_id, uid, user_display_name)
      update_user_photo_urls_in_orgs(user_org_id, uid, user_photo_url)
        





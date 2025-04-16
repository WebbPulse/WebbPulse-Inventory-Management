from src.helper_functions.users.update_user_display_names_in_orgs import update_user_display_names_in_orgs
from src.helper_functions.users.update_user_photo_urls_in_orgs import update_user_photo_urls_in_orgs

from firebase_admin import auth
from firebase_functions import firestore_fn
from firebase_functions.firestore_fn import (
  Event,
  Change,
  DocumentSnapshot,
)

@firestore_fn.on_document_updated(document="users/{userId}")
def monitor_for_user_changes(event: Event[Change[DocumentSnapshot]]) -> None:
    """
    Firestore trigger function that monitors updates to user documents in the 'users' collection.
    When a user document is updated, this function retrieves the user's associated organization IDs
    from their custom claims and updates their display name and photo URL in all relevant organizations.
    """
    
    # Step 1: Get the user's UID from the updated document.
    uid = event.data.after.get("uid")
    
    # Step 2: Retrieve the user's Firebase Auth record to get their custom claims.
    user = auth.get_user(uid)
    
    # Step 3: Extract custom claims (if any) from the user's Auth record.
    custom_claims = user.custom_claims or {}

    # Step 4: Extract organization IDs from the custom claims.
    # Custom claims related to organizations start with "org_member_" or "org_admin_".
    user_org_ids = [
        claim.split("_")[-1]  # Extract the organization ID from the claim string.
        for claim in custom_claims.keys()
        if claim.startswith("org_member_") or claim.startswith("org_admin_")
    ]

    # Step 5: Get the updated display name and photo URL from the Firestore user document.
    user_display_name = event.data.after.get("userDisplayName")
    user_photo_url = event.data.after.get("userPhotoURL")

    # Step 6: Loop through the organization IDs and update the user's display name and photo URL in each organization.
    for user_org_id in user_org_ids:
        # Update the user's display name in the organization.
        update_user_display_names_in_orgs(user_org_id, uid, user_display_name)
        
        # Update the user's photo URL in the organization.
        update_user_photo_urls_in_orgs(user_org_id, uid, user_photo_url)

from src.shared.shared import firestore_fn
from src.users.helpers.update_user_display_names_in_orgs import update_user_display_names_in_orgs
from firebase_functions.firestore_fn import (
  Event,
  Change,
  DocumentSnapshot,
)

@firestore_fn.on_document_updated(document="users/{userId}")
def monitor_for_user_changes(event: Event[Change[DocumentSnapshot]]) -> None:
    # Get the data from after the event
    org_ids = event.data.after.get("orgIds")
    uid = event.data.after.get("uid")
    display_name = event.data.after.get("displayName")
    # Update the user display name in all organizations
    for org_id in org_ids:
        update_user_display_names_in_orgs(org_id, uid, display_name)
        





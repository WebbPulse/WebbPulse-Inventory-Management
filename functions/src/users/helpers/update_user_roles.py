from src.shared.shared import https_fn, db, auth, time
from src.users.helpers.revoke_refresh_tokens import revoke_refresh_tokens

def update_user_roles(org_member_id, org_member_role, org_id, revoke_tokens):
    # Update role in Firestore
    db.collection('organizations').document(org_id).collection('members').document(org_member_id).update({
        'orgMemberRole': org_member_role 
    })
    
    # Retrieve existing custom claims
    user = auth.get_user(org_member_id)
    custom_claims = user.custom_claims or {}

    # Prepare the claims to update
    if org_member_role == "admin":
        custom_claims[f'org_admin_{org_id}'] = True
        custom_claims[f'org_member_{org_id}'] = True
    elif org_member_role == "member":
        custom_claims.pop(f'org_admin_{org_id}', None)  # Remove the admin claim if it exists
        custom_claims[f'org_member_{org_id}'] = True
    else:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f'Invalid role: {org_member_role}'
        )

    # Set the updated custom claims, ensuring to retain existing claims
    auth.set_custom_user_claims(org_member_id, custom_claims)

    # Optionally revoke tokens
    if revoke_tokens:
        revoke_refresh_tokens(org_member_id)

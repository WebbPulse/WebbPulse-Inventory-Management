from src.shared import https_fn, db, auth, time
from src.helper_functions.users.revoke_refresh_tokens import revoke_refresh_tokens

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
        custom_claims[f'org_admin_{org_id}'] = True #apply the admin role
        custom_claims.pop(f'org_member_{org_id}', None)
        custom_claims.pop(f'org_deskstation_{org_id}', None)
    elif org_member_role == "member":
        custom_claims.pop(f'org_admin_{org_id}', None)  
        custom_claims[f'org_member_{org_id}'] = True #apply the member role
        custom_claims.pop(f'org_deskstation_{org_id}', None)  
    elif org_member_role == "deskstation":
        custom_claims.pop(f'org_admin_{org_id}', None)
        custom_claims.pop(f'org_member_{org_id}', None)
        custom_claims[f'org_deskstation_{org_id}'] = True #apply the deskstation role
    elif org_member_role == "none":
        custom_claims.pop(f'org_admin_{org_id}', None)
        custom_claims.pop(f'org_member_{org_id}', None) #revoke ALL roles
        custom_claims.pop(f'org_deskstation_{org_id}', None)
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

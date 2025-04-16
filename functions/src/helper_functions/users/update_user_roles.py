from src.shared import db
from src.helper_functions.users.revoke_refresh_tokens import revoke_refresh_tokens

from firebase_functions import https_fn
from firebase_admin import auth

def update_user_roles(org_member_id, org_member_role, org_id, revoke_tokens):
    """
    Updates the role of a user in an organization and updates their custom claims in Firebase Auth.
    Optionally revokes the user's refresh tokens to ensure new tokens reflect the updated claims.

    Parameters:
    org_member_id (str): The user ID of the organization member whose role is being updated.
    org_member_role (str): The new role to assign to the user ('admin', 'member', 'deskstation', or 'none').
    org_id (str): The organization ID to which the user belongs.
    revoke_tokens (bool): Whether to revoke the user's refresh tokens after updating the role.
    """
    
    # Step 1: Update the user's role in Firestore.
    db.collection('organizations').document(org_id).collection('members').document(org_member_id).update({
        'orgMemberRole': org_member_role  # Set the new role for the user in Firestore.
    })
    
    # Step 2: Retrieve the user's existing custom claims from Firebase Authentication.
    user = auth.get_user(org_member_id)
    custom_claims = user.custom_claims or {}

    # Step 3: Prepare the custom claims to be updated based on the new role.
    if org_member_role == "admin":
        # Apply the 'admin' role, and remove 'member' and 'deskstation' roles if they exist.
        custom_claims[f'org_admin_{org_id}'] = True  # Set the admin role for the organization.
        custom_claims.pop(f'org_member_{org_id}', None)  # Remove member role.
        custom_claims.pop(f'org_deskstation_{org_id}', None)  # Remove deskstation role.
    elif org_member_role == "member":
        # Apply the 'member' role, and remove 'admin' and 'deskstation' roles if they exist.
        custom_claims.pop(f'org_admin_{org_id}', None)  # Remove admin role.
        custom_claims[f'org_member_{org_id}'] = True  # Set the member role for the organization.
        custom_claims.pop(f'org_deskstation_{org_id}', None)  # Remove deskstation role.
    elif org_member_role == "deskstation":
        # Apply the 'deskstation' role, and remove 'admin' and 'member' roles if they exist.
        custom_claims.pop(f'org_admin_{org_id}', None)  # Remove admin role.
        custom_claims.pop(f'org_member_{org_id}', None)  # Remove member role.
        custom_claims[f'org_deskstation_{org_id}'] = True  # Set the deskstation role for the organization.
    elif org_member_role == "none":
        # Remove all roles ('admin', 'member', and 'deskstation').
        custom_claims.pop(f'org_admin_{org_id}', None)  # Remove admin role.
        custom_claims.pop(f'org_member_{org_id}', None)  # Remove member role.
        custom_claims.pop(f'org_deskstation_{org_id}', None)  # Remove deskstation role.
    else:
        # Raise an error if the provided role is invalid.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f'Invalid role: {org_member_role}'
        )

    # Step 4: Update the user's custom claims in Firebase Authentication with the new role(s).
    auth.set_custom_user_claims(org_member_id, custom_claims)

    # Step 5: Optionally revoke the user's refresh tokens to force new tokens with the updated claims.
    if revoke_tokens:
        revoke_refresh_tokens(org_member_id)

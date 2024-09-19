from src.shared import db, firestore, https_fn, auth
from src.helper_functions.users.update_user_roles import update_user_roles

def add_user_to_organization(uid, org_id, org_member_display_name, org_member_email):
    """
    Adds a user to an organization by creating a member record in the organization's 'members' subcollection in Firestore.
    The function assigns the user the role of 'member' and updates their roles in the system.

    Parameters:
    uid (str): The user ID of the member to be added.
    org_id (str): The organization ID to which the user is being added.
    org_member_display_name (str): The display name of the user (can be empty or None).
    org_member_email (str): The email address of the user.
    """
    try:
        # Step 1: Use the user's email as their display name if the display name is not provided.
        org_member_display_name = org_member_display_name or org_member_email

        # Step 2: Create a reference to the organization's 'members' subcollection in Firestore.
        org_member_ref = db.collection('organizations').document(org_id).collection('members').document(uid)
        
        # Step 3: Set the user's member document in Firestore with the relevant details.
        org_member_ref.set({
            'orgMemberId': uid,  # The user ID.
            'createdAt': firestore.SERVER_TIMESTAMP,  # The timestamp of when the user was added.
            'orgMemberDisplayName': org_member_display_name,  # The display name of the user.
            'orgMemberEmail': org_member_email,  # The email address of the user.
            'orgMemberPhotoURL': "",  # Initially, the user's photo URL is set to an empty string.
            'orgMemberRole': "member",  # The user's role is set to 'member'.
            'orgMemberDeleted': False,  # The user is marked as active (not deleted).
        })

        # Step 4: Update the user's roles after successfully adding them to the organization.
        # False indicates that the user's refresh token is not revoked immediately.
        update_user_roles(uid, "member", org_id, False)
        
    except Exception as e:
        # Step 5: Handle any unexpected exceptions by raising an UNKNOWN error with details of the exception.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Unknown Error adding user to organization: {str(e)}"
        )

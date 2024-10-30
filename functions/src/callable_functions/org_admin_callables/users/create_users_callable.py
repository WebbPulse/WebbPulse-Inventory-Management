from src.shared import auth, https_fn, POSTcorsrules, Any, UserNotFoundError, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, db
from src.helper_functions.users.create_global_user_profile import create_global_user_profile
from src.helper_functions.users.add_user_to_organization import add_user_to_organization

@https_fn.on_call(cors=POSTcorsrules, timeout_sec=540)
def create_users_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to create or add users to an organization based on a list of emails.
    The function ensures the user is authenticated, their email is verified, their token is current, 
    and they are an admin of the specified organization.
    It either creates new users or adds existing ones to the organization, handling any errors encountered.
    """
    try:
        # Step 1: Extract the list of user emails and organization ID from the request data.
        user_emails = req.data.get("userEmails")  # List of emails to create or add.
        org_id = req.data.get("orgId")  # Organization ID to add the users to.
        
        # Step 2: Validate the required fields.
        if not user_emails or not org_id:
            # Raise an error if either userEmails or orgId is missing.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with "userEmails" (list) and "orgId".'
            )

        # Step 3: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Ensure the user is an admin of the specified organization.

        response_messages = []  # List to store response messages for each email.

        # Step 4: Get the inviter's display name.
        inviter_doc_ref = db.collection('users').document(req.auth.uid)
        inviter_doc = inviter_doc_ref.get()
        if inviter_doc.exists:
            inviter_user_data = inviter_doc.to_dict()
            inviter_display_name = inviter_user_data.get('userDisplayName')
        else:
            inviter_display_name = "Admin"

    
        # Step 5: Loop through each email in the list and process the user.
        for user_email in user_emails:
            user, user_was_created = None, False  # Initialize variables.

            # Step 6: Check if the user already exists in Firebase Auth.
            try:
                user = auth.get_user_by_email(user_email)  # Try to get the user by their email.
            except UserNotFoundError:
                # If the user does not exist, create a new user in Firebase Auth.
                user = auth.create_user(
                    email=user_email,
                    email_verified=False,  # Newly created users' emails are not verified.
                    disabled=False
                )
                user_was_created = True  # Set flag indicating the user was newly created.

            # Step 7: If the user was created, create a global user profile.
            if user_was_created:
                create_global_user_profile(user, inviter_display_name)

            # Step 8: Check if the user has reached the global organization limit.
            if check_user_is_at_global_org_limit(user.uid):
                response_messages.append(f"User {user_email} is at the global organization limit.")
                continue  # Skip adding the user if the limit is reached.

            # Step 9: Check if the user already belongs to the organization.
            if check_user_already_belongs_to_org(user.uid, org_id):
                response_messages.append(f"User {user_email} already belongs to the organization.")
                continue  # Skip adding the user if they are already in the organization.

            # Step 10: Add the user to the organization.
            add_user_to_organization(user.uid, org_id, user.display_name, user_email, inviter_display_name)

            # Step 11: Generate a response message for this email.
            response_message = f"User {user_email} {'created and ' if user_was_created else ''}added to organization."
            response_messages.append(response_message)

        # Step 12: Return a response with messages for all processed emails.
        return {"response": response_messages}

    except https_fn.HttpsError as e:
        # Catch and re-raise known Firebase HttpsErrors.
        raise e

    except Exception as e:
        # Catch any unexpected errors and return a generic error message.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating users: {str(e)}"
        )

def check_user_already_belongs_to_org(uid: str, org_id: str) -> bool:
    """
    Checks if the user already belongs to the organization based on their custom claims.
    Returns True if the user is already a member or admin of the organization.
    """
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    # Check for organization-specific claims indicating admin, member, or deskstation roles.
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    
    # Return True if the user has any relevant claims for the organization.
    return f"org_admin_{org_id}" in org_admin_claims or f"org_member_{org_id}" in org_member_claims or f"org_deskstation_{org_id}" in org_deskstation_claims

def check_user_is_at_global_org_limit(uid: str) -> bool:
    """
    Checks if the user has reached the global organization limit based on their custom claims.
    Returns True if the user is at the limit of 10 organizations.
    """
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    # Count the number of organization-related claims the user has.
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    org_count = len(org_admin_claims) + len(org_member_claims) + len(org_deskstation_claims)
    
    # Return True if the user belongs to 10 or more organizations.
    return org_count >= 10

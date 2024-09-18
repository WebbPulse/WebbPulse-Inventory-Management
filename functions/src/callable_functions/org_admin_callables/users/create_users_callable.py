from src.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any, UserNotFoundError, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.helper_functions.users.create_global_user_profile import create_global_user_profile
from src.helper_functions.users.add_user_to_organization import add_user_to_organization


@https_fn.on_call(cors=POSTcorsrules)
def create_users_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract required data from the request
        user_emails = req.data.get("userEmails")  # Expecting a list of emails
        org_id = req.data.get("orgId")
        
        # Validate required fields
        if not user_emails or not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with "userEmails" (list) and "orgId".'
            )

        # Run authentication and authorization checks
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        response_messages = []

        # Loop through each email and attempt to create/add the user
        for user_email in user_emails:
            # Validate email domain
            if user_email.split("@")[1] not in allowed_domains:
                response_messages.append(f'Unauthorized email: {user_email}')
                continue

            # Check if the user already exists in Firebase Auth
            user, user_was_created = None, False
            try:
                user = auth.get_user_by_email(user_email)
            except UserNotFoundError:
                # User does not exist, create the user
                user = auth.create_user(
                    email=user_email,
                    email_verified=False,
                    disabled=False
                )
                user_was_created = True

            # If the user was newly created, create a global user profile
            if user_was_created:
                create_global_user_profile(user)

            # Check if the user is at the global organization limit
            org_limit_reached = check_user_is_at_global_org_limit(user.uid)
            if org_limit_reached:
                response_messages.append(f"User {user_email} is at the global organization limit.")
                continue

            # Check if user already belongs to the organization
            already_in_org = check_user_already_belongs_to_org(user.uid, org_id)
            if already_in_org:
                response_messages.append(f"User {user_email} already belongs to the organization.")
                continue

            # Add the user to the organization
            add_user_to_organization(user.uid, org_id, user.display_name, user_email)

            # Return success message for this email
            response_message = f"User {user_email} {'created and ' if user_was_created else ''}added to organization."
            response_messages.append(response_message)

        # Return a response with messages for all emails
        return {"response": response_messages}

    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Catch any unexpected errors and return a generic error message
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating users: {str(e)}"
        )

def check_user_already_belongs_to_org(uid: str, org_id: str) -> bool:
    # Check if the user already belongs to the organization
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    
    return f"org_admin_{org_id}" in org_admin_claims or f"org_member_{org_id}" in org_member_claims or f"org_deskstation_{org_id}" in org_deskstation_claims

def check_user_is_at_global_org_limit(uid: str) -> bool:
    # Check if the user is at the global organization limit
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    org_count = len(org_admin_claims) + len(org_member_claims) + len(org_deskstation_claims)
    
    return org_count >= 10

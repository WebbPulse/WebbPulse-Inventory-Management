from src.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, check_user_is_at_global_org_limit
from src.helper_functions.users.create_global_user_profile import create_global_user_profile
from src.helper_functions.users.add_user_to_organization import add_user_to_organization


@https_fn.on_call(cors=POSTcorsrules)
def create_user_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract required data from the request
        user_email = req.data.get("userEmail")
        org_id = req.data.get("orgId")
        
        # Validate required fields
        if not user_email or not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with "userEmail" and "orgId".'
            )

        # Run authentication and authorization checks
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        # Validate email domain
        if user_email.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='Unauthorized email for new user'
            )

        # Check if the user is at the global organization limit
        check_user_is_at_global_org_limit(req, user_email)
        
        # Check if the user already exists in Firebase Auth
        user, user_was_created = None, False
        try:
            user = auth.get_user_by_email(user_email)
        except auth.UserNotFoundError:
            # User does not exist, create the user
            user = auth.create_user(
                email=user_email,
                email_verified=False,
                disabled=False
            )
            user_was_created = True
        except Exception as e:
            # Handle any other unexpected errors
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNKNOWN,
                message=f"Error retrieving or creating user: {str(e)}"
            )

        # If the user was newly created, create a global user profile
        if user_was_created:
            create_global_user_profile(user)

        # Add the user to the organization
        add_user_to_organization(user.uid, org_id, user.display_name, user_email)

        # Return response indicating the operation success
        response_message = f"User {user_email} {'created and ' if user_was_created else ''}added to organization."
        return {"response": response_message}

    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Catch any unexpected errors and return a generic error message
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )



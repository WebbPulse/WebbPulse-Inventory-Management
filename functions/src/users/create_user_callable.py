from src.shared.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any, UserNotFoundError
from src.users.helpers.create_global_user_profile import create_global_user_profile
from src.users.helpers.add_user_to_organization import add_user_to_organization
from src.users.helpers.update_user_organizations import update_user_organizations


@https_fn.on_call(cors=POSTcorsrules)
def create_user_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try: 
        user_email = req.data["userEmail"]
        org_id = req.data["orgId"]
        
        # Checking that the user is authenticated.
        if req.auth is None:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                                      message="The function must be called while authenticated.")
        
        # Check if the token is valid based on the revokeTime custom claim
        auth_time = req.auth.token.get('auth_time', 0)  # auth_time in seconds
        revoke_time = req.auth.token.get('revokeTime', 0)  # revokeTime in seconds
        
        if revoke_time < auth_time:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="The session has been revoked. Please sign in again."
            )
        
        # Check for the admin role
        is_admin = req.auth.token.get(f"org_admin_{org_id}", None)
        if not is_admin:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                                      message=f"Unauthorized access.")

        # Checking attribute.
        if not user_email or not org_id:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                      message='The function must be called with two arguments: "userEmail" and "orgId".')

        if user_email.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                      message='Unauthorized email for new user')

        user = None
        response_message = ""

        def user_exists_in_auth():
            nonlocal user
            try:
                # User exists
                user = auth.get_user_by_email(user_email)
                return True
                    
            except auth.UserNotFoundError:
                # Create the user in Firebase Auth
                user = auth.create_user(
                    email=user_email,
                    email_verified=False,
                    disabled=False
                )
                return False

        if user_exists_in_auth():   
            add_user_to_organization(user.uid, org_id, user.display_name, user_email)
            update_user_organizations(user.uid, org_id)
            response_message = f"User {user_email} added to organization."
        else:
            create_global_user_profile(user)
            add_user_to_organization(user.uid, org_id, user.display_name, user_email)
            update_user_organizations(user.uid, org_id)
            response_message = f"User {user_email} created and added to organization."

        return {"response": response_message,
                "token": req.auth.token}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )

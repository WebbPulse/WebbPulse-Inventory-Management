from src.shared.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any
from src.users.helpers.create_user_profile import create_user_profile
from src.users.helpers.add_user_to_organization import add_user_to_organization
from src.users.helpers.update_user_organizations import update_user_organizations


@https_fn.on_call(cors=POSTcorsrules)
def create_user_callable(req: https_fn.CallableRequest) -> Any:
    #create the user in firebase auth
    try:
        # Checking that the user is authenticated.
        if req.auth is None:
        # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                                message="The function must be called while authenticated.")
        
        # Extract parameters 
        new_user_dispay_name = req.data["userCreationDisplayName"]
        new_user_email = req.data["userCreationEmail"]
        organization_uid = req.data["organizationUid"]

        # Checking attribute.
        if not new_user_dispay_name or not new_user_email or not organization_uid:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with three arguments: "userCreationDisplayName", "userCreationEmail", and "organizationUid".')

        if new_user_email.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='Unauthorized email for new user')

        #create the user in firebase auth
        user = auth.create_user(
            email=new_user_email,
            email_verified=False,
            display_name=new_user_dispay_name,
            disabled=False
        )
        #create the user profile in firestore
        create_user_profile(user)
        add_user_to_organization(req.auth.uid, organization_uid, new_user_dispay_name, new_user_email)
        update_user_organizations(req.auth.uid, organization_uid)

        return {"response": f"User {new_user_email} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )
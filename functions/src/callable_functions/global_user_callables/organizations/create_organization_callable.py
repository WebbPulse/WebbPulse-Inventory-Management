from src.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_authed, check_user_token_current, check_user_is_email_verified, check_user_is_at_global_org_limit
from src.helper_functions.users.add_user_to_organization import add_user_to_organization
from src.helper_functions.users.update_user_roles import update_user_roles

@https_fn.on_call(cors=POSTcorsrules)
def create_organization_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        org_name = req.data["orgName"]
        uid = req.auth.uid
        org_member_display_name = req.auth.token.get("name", "")
        org_member_email = req.auth.token.get("email", "")
        
        if org_member_display_name == "":
            org_member_display_name = org_member_email

        # Check if the user is authenticated
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        # Check if the user is at the global organization limit, if so, prevent the user from creating a new organization
        check_user_is_at_global_org_limit(uid)


        # Check if the organization_creation_name is provided and valid
        if not org_name:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid "organizationCreationName" argument.'
            )

        # Create the organization in Firestore
        org_ref = db.collection('organizations').document()
        org_id = org_ref.id  # Directly use the generated ID
        org_ref.set({
            'orgId': org_id,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'orgName': org_name,
            'orgBackgroundImageURL': "",
            'orgDeleted': False,
        })

        add_user_to_organization(uid, org_id, org_member_display_name, org_member_email)
        update_user_roles(uid, "admin", org_id, False)

        return {"response": f"Organization {org_id} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating organization: {str(e)}"
        )

from src.shared.shared import POSTcorsrules, db, firestore, https_fn, Any
from src.users.helpers.add_user_to_organization import add_user_to_organization
from src.users.helpers.update_user_organizations import update_user_organizations

@https_fn.on_call(cors=POSTcorsrules)
def create_organization_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Check if the user is authenticated
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="The function must be called while authenticated."
            )

        # Extract parameters
        org_name = req.data["orgName"]
        uid = req.auth.uid
        org_member_display_name = req.auth.token.get("name", "")
        org_member_email = req.auth.token.get("email", "")

        # Check if the organization_creation_name is provided and valid
        if not org_name:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid "organizationCreationName" argument.'
            )

        # Create the organization in Firestore
        org_ref = db.collection('organizations').document()
        org_ref.set({
            'orgId': org_ref.id,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'orgName': org_name,
        })

        # Retrieve the newly created organization UID
        org_id = db.collection('organizations').where('orgName', '==', org_name).get()[0].id

        # Update user organizations and add user to the organization
        update_user_organizations(uid, org_id)
        add_user_to_organization(uid, org_id, org_member_display_name, org_member_email)

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
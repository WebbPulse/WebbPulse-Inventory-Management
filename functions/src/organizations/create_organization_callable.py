from src.shared.shared import POSTcorsrules, db, firestore, https_fn, Any
from src.organizations.helpers.add_user_to_organization import add_user_to_organization
from src.organizations.helpers.update_user_organizations import update_user_organizations

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
        organization_creation_name = req.data["organizationCreationName"]
        uid = req.auth.uid
        display_name = req.auth.token.get("name", "")
        email = req.auth.token.get("email", "")

        # Check if the organization_creation_name is provided and valid
        if not organization_creation_name:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid "organizationCreationName" argument.'
            )

        # Create the organization in Firestore
        db.collection('organizations').add({
            'created_at': firestore.SERVER_TIMESTAMP,
            'name': organization_creation_name,
        })

        # Retrieve the newly created organization UID
        organization_uid = db.collection('organizations').where('name', '==', organization_creation_name).get()[0].id

        # Update user organizations and add user to the organization
        update_user_organizations(uid, organization_uid)
        add_user_to_organization(uid, organization_uid, display_name, email)

        return {"response": f"Organization {organization_uid} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating organization: {str(e)}"
        )
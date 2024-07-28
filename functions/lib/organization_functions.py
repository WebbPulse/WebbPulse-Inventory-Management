from firebase_functions import https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import firestore
import google.cloud.firestore as gcf
from typing import Any

from main import db, POSTcorsrules

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


def update_user_organizations(uid, organization_uid):
    try:
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'organizationUids': gcf.ArrayUnion([organization_uid])
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error updating user organizations: {str(e)}")

def add_user_to_organization(uid, organization_uid, display_name, email):
    try:
        db.collection('organizations').document(organization_uid).collection('members').document(uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'username': display_name,
            'email': email,
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error adding user to organization: {str(e)}")
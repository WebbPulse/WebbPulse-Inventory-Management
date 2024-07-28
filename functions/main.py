# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn, identity_fn, options

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials, auth
import google.cloud.firestore as gcf
from typing import Any


allowed_domains = ["verkada.com", "gmail.com"]


# Read the service account key from the file

cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)
db = firestore.client()

POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])

def create_user_profile(user):
    try:
        user_data = {
            'created_at': firestore.SERVER_TIMESTAMP,
            'email': user.email,
            'organizationUids': [],
            'uid': user.uid,
            'username': user.display_name,
        }
        db.collection('users').document(user.uid).set(user_data)
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error creating user profile: {str(e)}")
@identity_fn.before_user_created()
def create_user_ui(event: identity_fn.AuthBlockingEvent) -> identity_fn.BeforeCreateResponse | None:
    user = event.data
    try:
        if not user.email or user.email.split("@")[1] not in allowed_domains:
            return https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Unauthorized email"
            )
        create_user_profile(user)
    except https_fn.HttpsError as e:
        return identity_fn.BeforeCreateResponse(
            error=identity_fn.Error(
                message=e.message,
                code=e.code
            )
        )




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
        new_user_dispay_name = req.data["newUserDisplayName"]
        new_user_email = req.data["newUserEmail"]

        # Checking attribute.
        if not new_user_dispay_name or not new_user_email:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with two arguments, "new_user_dispay_name" and "new_user_email"')

        if new_user_dispay_name.split("@")[1] not in allowed_domains:
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
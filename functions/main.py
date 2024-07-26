# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn, identity_fn
from firebase_functions.params import SecretParam

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials, auth
import google.cloud.firestore as gcf


allowed_domains = ["verkada.com", "gmail.com"]

# Read the service account key from the file

cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)
db = firestore.client()

db = firestore.client()

def create_user_profile(user) -> None:
    user_data = {
        'created_at': firestore.SERVER_TIMESTAMP,
        'email': user.email,
        'organizationUids': [],
        'uid': user.uid,
        'username': user.display_name,
    }
    db.collection('users').document(user.uid).set(user_data)

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


@https_fn.on_request()
def create_user_https(req: https_fn.Request) -> https_fn.Response:
    email = req.args.get("email")
    display_name = req.args.get("display_name")

    if not email or not display_name:
        return https_fn.Response("Not all parameters provided", status=400)

    if email.split("@")[1] not in allowed_domains:
        return https_fn.Response("Unauthorized email", status=403)
    try:
        #create the user in firebase auth
        user = auth.create_user(
            email=email,
            email_verified=False,
            display_name=display_name,
            disabled=False
        )
        #create the user profile in firestore
        create_user_profile(user)

        return https_fn.Response(f"User {user.uid} created", status=200)
    except Exception as e:
        return https_fn.Response(f"Error creating user: {str(e)}", status=500)

@https_fn.on_request()
def create_organization_https(req: https_fn.Request) -> https_fn.Response:
    organization_creation_name = req.args.get("organizationCreationName")
    uid = req.args.get("uid")
    display_name = req.args.get("displayName")
    email = req.args.get("email")

    if not organization_creation_name or not uid:
        return https_fn.Response("Not all parameters provided", status=400)
    
    #create the organization in firestore
    try:
        org_data = {
            'created_at': firestore.SERVER_TIMESTAMP,
            'name': organization_creation_name,
        }
        db.collection('organizations').add(org_data)
        organization_uid = db.collection('organizations').where('name', '==', organization_creation_name).get()[0].id
        update_user_organizations(uid, organization_uid)
        add_user_to_organization(uid, organization_uid, display_name, email)

        return https_fn.Response(f"Organization {organization_creation_name} created", status=200)
    
    except Exception as e:
        return https_fn.Response(f"Error creating organization: {str(e)}", status=500)
    


def update_user_organizations(uid, organization_uid):
    
    try:
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'organizationUids': gcf.ArrayUnion([organization_uid])
        })
    except Exception as e:
        print(f"Error updating user: {str(e)}")

def add_user_to_organization(uid, organization_uid, display_name, email):
    try:
        db.collection('organizations').document(organization_uid).collection('members').document(uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'username': display_name,
            'email': email,
        })
    except Exception as e:
        print(f"Error updating organization: {str(e)}")
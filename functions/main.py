# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn, identity_fn, options

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


POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])

@https_fn.on_request(cors=POSTcorsrules)
def create_user_https(req: https_fn.Request) -> https_fn.Response:
    #create the user in firebase auth
    try:
        # Read JSON data from request body
        data = req.get_json()
        
        # Extract parameters from JSON data
        display_name = data.get("displayName")
        email = data.get("email")

        if not email or not display_name:
            return https_fn.Response(response="Not all parameters provided", status=400)

        if email.split("@")[1] not in allowed_domains:
            return https_fn.Response(response="Unauthorized email", status=403)

        #create the user in firebase auth
        user = auth.create_user(
            email=email,
            email_verified=False,
            display_name=display_name,
            disabled=False
        )
        #create the user profile in firestore
        create_user_profile(user)

        return https_fn.Response(response=f"User {user.uid} created", status=200)
    except Exception as e:
        return https_fn.Response(response=f"Error creating user: {str(e)}", status=500)



@https_fn.on_request(cors=POSTcorsrules)
def create_organization_https(req: https_fn.Request) -> https_fn.Response:
    #create the organization in firestore
    # Set CORS headers for the preflight request
    try:
        # Read JSON data from request body
        data = req.get_json().get("data", {})
        
        # Extract parameters from JSON data
        organization_creation_name = data.get("organizationCreationName")
        uid = data.get("uid")
        display_name = data.get("displayName")
        email = data.get("email")

        if not organization_creation_name or not uid or not display_name or not email:
            return https_fn.Response(response="Not all parameters provided", status=400)
    
        org_data = {
            'created_at': firestore.SERVER_TIMESTAMP,
            'name': organization_creation_name,
        }
        db.collection('organizations').add(org_data)
        organization_uid = db.collection('organizations').where('name', '==', organization_creation_name).get()[0].id
        update_user_organizations(uid, organization_uid)
        add_user_to_organization(uid, organization_uid, display_name, email)

        return https_fn.Response(response={
            "response":{
                "message": f"Organization {organization_creation_name} created"
                }
            }, status=200)
    
    except Exception as e:
        return https_fn.Response(response=f"Error creating organization: {str(e)}", status=500)

    


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
from src.shared.shared import db, firestore, https_fn

def add_user_to_organization(uid, organization_uid, display_name, email):
    try:
        db.collection('organizations').document(organization_uid).collection('members').document(uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'username': display_name,
            'email': email,
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error adding user to organization: {str(e)}")
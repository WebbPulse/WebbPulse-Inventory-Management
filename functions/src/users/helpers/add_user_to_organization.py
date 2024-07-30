from src.shared.shared import db, firestore, https_fn

def add_user_to_organization(uid, org_id, display_name, email):
    try:
        db.collection('organizations').document(org_id).collection('members').document(uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'displayName': display_name,
            'email': email,
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error adding user to organization: {str(e)}")
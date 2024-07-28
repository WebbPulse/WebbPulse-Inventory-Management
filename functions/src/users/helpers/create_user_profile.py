from src.shared.shared import db, firestore, https_fn

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
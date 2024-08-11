from src.shared.shared import db, firestore, https_fn

def create_global_user_profile(user):
    try:
        user_data = {
            'createdAt': firestore.SERVER_TIMESTAMP,
            'userEmail': user.email,
            'userOrgIds': [],
            'uid': user.uid,
            'userDisplayName': user.email,
            'userPhotoURL': "",
        }
        db.collection('users').document(user.uid).set(user_data)
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error creating user profile: {str(e)}")
    

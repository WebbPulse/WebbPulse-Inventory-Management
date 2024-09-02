from src.shared import db, firestore, https_fn

def create_global_user_profile(user):
    try:
        db.collection('users').document(user.uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'userEmail': user.email,
            'userOrgIds': [],
            'uid': user.uid,
            'userDisplayName': user.email,
            'userPhotoURL': "",
            'userDeleted': False,
        })
        db.collection('usersMetadata').document(user.uid).set({
            'mostRecentTokenRevokeTime': 0
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error creating user profile: {str(e)}")
    

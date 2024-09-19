from src.shared import db, firestore, https_fn

def create_global_user_profile(user):
    """
    Creates a global user profile in Firestore for a newly registered user.
    The function sets up two documents: one in the 'users' collection and one in the 'usersMetadata' collection.

    Parameters:
    user (AuthUserRecord): The user object from Firebase Authentication containing details like UID and email.
    """
    try:
        # Step 1: Create a document in the 'users' collection for the new user.
        db.collection('users').document(user.uid).set({
            'createdAt': firestore.SERVER_TIMESTAMP,  # Record the timestamp when the profile is created.
            'userEmail': user.email,  # Store the user's email address.
            'userOrgIds': [],  # Initialize an empty list for organization IDs the user is part of.
            'uid': user.uid,  # Store the user's unique ID.
            'userDisplayName': user.email,  # Initially, set the display name to the user's email.
            'userPhotoURL': "",  # Set the photo URL to an empty string initially.
            'userDeleted': False,  # Mark the user as active (not deleted).
        })

        # Step 2: Create a corresponding document in the 'usersMetadata' collection.
        db.collection('usersMetadata').document(user.uid).set({
            'mostRecentTokenRevokeTime': 0  # Initialize the token revoke time to 0.
        })

    except Exception as e:
        # Step 3: Handle any unexpected exceptions by raising an UNKNOWN error with details of the exception.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Unknown Error creating user profile: {str(e)}"
        )

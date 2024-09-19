from src.shared import db, auth, time

def revoke_refresh_tokens(org_member_id):
    """
    Revokes the refresh tokens for a given user to force re-authentication.
    This ensures that any updated claims will be included in new tokens.
    
    Parameters:
    org_member_id (str): The user ID of the organization member whose tokens are being revoked.
    """
    
    # Step 1: Revoke the user's refresh tokens using Firebase Authentication.
    # This forces the user to reauthenticate, ensuring that new tokens reflect any updated claims.
    auth.revoke_refresh_tokens(org_member_id)
    
    # Step 2: Update the 'usersMetadata' collection in Firestore.
    # Record the most recent token revoke time as the current timestamp (in seconds).
    db.collection('usersMetadata').document(org_member_id).update({
        'mostRecentTokenRevokeTime': time.time()  # Store the current time as the revoke timestamp.
    })

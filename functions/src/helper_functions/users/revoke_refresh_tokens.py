from src.shared import db, auth, time
def revoke_refresh_tokens(org_member_id):
    # Revoke the refresh tokens to ensure new tokens will include the updated claims
    auth.revoke_refresh_tokens(org_member_id)
    # Mark metadata revoke time in firestore
    db.collection('usersMetadata').document(org_member_id).update({
        'mostRecentTokenRevokeTime': time.time()
    })
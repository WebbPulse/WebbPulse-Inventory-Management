from shared.shared import https_fn, db, auth, time

def update_user_roles(org_member_id, org_member_role, org_id):
            # Retrieve existing custom claims
            user = auth.get_user(org_member_id)
            
            custom_claims = user.custom_claims or {}

            # Update claims based on role
            if org_member_role == "admin":
                custom_claims[f'org_admin_{org_id}'] = True
                custom_claims[f'org_member_{org_id}'] = True
            elif org_member_role == "member":
                custom_claims.pop(f'org_admin_{org_id}', None)  # Remove the admin claim
                custom_claims[f'org_member_{org_id}'] = True
            else:
               raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                    message=f'Invalid role: {org_member_role}'
                )
            # Set the updated custom claims
            auth.set_custom_user_claims(org_member_id, custom_claims)
            # Revoke the refresh tokens to ensure new tokens will include the updated claims
            auth.revoke_refresh_tokens(org_member_id)
            # Mark metadata revoke time in firestore
            db.collection('usersMetadata').document(org_member_id).update({
                'mostRecentTokenRevokeTime': time.time()
            })
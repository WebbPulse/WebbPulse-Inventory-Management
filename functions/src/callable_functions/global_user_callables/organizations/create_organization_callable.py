from src.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_authed, check_user_token_current, check_user_is_email_verified, check_user_is_at_global_org_limit
from src.helper_functions.users.add_user_to_organization import add_user_to_organization
from src.helper_functions.users.update_user_roles import update_user_roles

@https_fn.on_call(cors=POSTcorsrules)
def create_organization_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to create a new organization.
    The function ensures the user is authenticated, verifies their email, checks if they are at the organization creation limit,
    and if valid, creates a new organization document in Firestore.
    """
    try:
        # Step 1: Extract organization name and user information from the request.
        org_name = req.data["orgName"]  # Organization name from the request data.
        uid = req.auth.uid  # User ID from the authenticated request.
        org_member_display_name = req.auth.token.get("name", "")  # Attempt to retrieve display name from token.
        org_member_email = req.auth.token.get("email", "")  # User email from token.

        # Step 2: If no display name is provided, default to using the user's email as their display name.
        if org_member_display_name == "":
            org_member_display_name = org_member_email

        # Step 3: Perform user authentication and validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Verify that the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is current.
        
        # Step 4: Check if the user has reached the global organization creation limit.
        check_user_is_at_global_org_limit(uid)  # Prevent the user from creating another organization if limit is reached.

        # Step 5: Validate that the organization name is provided and not empty.
        if not org_name:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid "organizationCreationName" argument.'
            )

        # Step 6: Create a new organization document in Firestore with a unique ID.
        org_ref = db.collection('organizations').document()  # Generate a reference to a new organization document.
        org_id = org_ref.id  # Get the auto-generated document ID.

        # Step 7: Set the organization data in Firestore with default values.
        org_ref.set({
            'orgId': org_id,  # Assign the generated organization ID.
            'createdAt': firestore.SERVER_TIMESTAMP,  # Record the creation timestamp.
            'orgName': org_name,  # Set the organization name from the request.
            'orgBackgroundImageURL': "",  # Default empty background image URL.
            'orgDeleted': False,  # Mark the organization as active (not deleted).
        })

        # Step 8: Add the user to the organization as a member and set their role as an admin.
        add_user_to_organization(uid, org_id, org_member_display_name, org_member_email, org_member_display_name)  # Add the user to the organization.
        update_user_roles(uid, "admin", org_id, False)  # Assign the user an admin role for the organization.

        # Step 9: Return a success response with the organization ID.
        return {"response": f"Organization {org_id} created"}

    # Catch and re-raise any known Firebase HttpsErrors to preserve their error messages and codes.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unknown exceptions and return a generic UNKNOWN error with the exception message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating organization: {str(e)}"
        )

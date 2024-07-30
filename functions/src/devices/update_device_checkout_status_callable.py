from src.shared.shared import POSTcorsrules, db, firestore, https_fn, Any

@https_fn.on_call(cors=POSTcorsrules)
def update_device_checkout_status_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Check if the user is authenticated
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="The function must be called while authenticated."
            )

        # Extract parameters
        serial = req.data["deviceSerialNumber"]
        org_id = req.data["orgId"]
        isCheckedOut = req.data["isCheckedOut"]
        
        # Check if the serial, org_id, and isCheckedOut are provided and valid
        if not serial or not org_id or isCheckedOut is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with valid "serial", "org_id", and "isCheckedOut" arguments.'
            )

        # Update the device in Firestore
        querySnapshot = db.collection('organizations').document(org_id).collection('devices').where('serial', '==', serial).get()
        if len(querySnapshot) > 0:
            docId = querySnapshot[0].id
            db.collection('organizations').document(org_id).collection('devices').document(docId).update({
                'isCheckedOut': isCheckedOut,
            })
        else:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message='Device not found'
            )

        return {"response": f"Device {serial} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error updating device checkout status: {str(e)}"
        )
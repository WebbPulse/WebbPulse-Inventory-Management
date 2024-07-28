# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn, identity_fn, options
# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, credentials
import google.cloud.firestore as gcf



allowed_domains = ["verkada.com", "gmail.com"]
POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])



# Initialize Firebase app
cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)
db = firestore.client()


import functions.lib.auth_functions
import functions.lib.organization_functions
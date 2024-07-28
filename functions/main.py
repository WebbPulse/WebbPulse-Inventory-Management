from firebase_admin import initialize_app, firestore, credentials
from firebase_functions import options

allowed_domains = ["verkada.com", "gmail.com"]
POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])



# Initialize Firebase app
cred = credentials.Certificate('./gcp_key.json')
app = initialize_app(cred)
db = firestore.client()

# Import functions
import functions.lib.auth_functions
import functions.lib.organization_functions


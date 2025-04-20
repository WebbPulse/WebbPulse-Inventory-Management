from firebase_functions import options
from firebase_admin import firestore

# Define CORS options for HTTP functions
POSTcorsrules = options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])

# Initialize Firestore client
db = firestore.client()
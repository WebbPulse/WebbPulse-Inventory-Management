from firebase_functions import options
from firebase_admin import firestore
import logging

# Define CORS options for HTTP functions
POSTcorsrules = options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])

# Initialize Firestore client
db = firestore.client()

# Configure logging
logging.basicConfig(level=logging.info, format='%(asctime)s - %(levelname)s - %(message)s')

# Create a logger instance
logger = logging.getLogger(__name__)
from firebase_functions import options, https_fn, identity_fn
from firebase_admin import firestore, auth
import google.cloud.firestore as gcf
from typing import Any

allowed_domains = ["verkada.com"]
POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])
db = firestore.client()
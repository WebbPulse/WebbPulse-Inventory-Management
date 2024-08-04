from firebase_functions import options, https_fn, identity_fn, firestore_fn
from firebase_admin import firestore, auth
from firebase_admin.auth import UserNotFoundError
import google.cloud.firestore as gcf
from typing import Any

allowed_domains = ["gmail.com","verkada.com"]
corsrules=options.CorsOptions(cors_origins="*", cors_methods="*")
db = firestore.client()
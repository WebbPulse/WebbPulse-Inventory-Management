from firebase_functions import options, https_fn, identity_fn, firestore_fn
from firebase_admin import firestore, auth
from firebase_admin.auth import UserNotFoundError
import google.cloud.firestore as gcf
from typing import Any
import time

allowed_domains = ["gmail.com","verkada.com"]
POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])
db = firestore.client()
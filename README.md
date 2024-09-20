# WebbPulse Inventory Management

A program built in flutter to do simple tracking of device checkout status

# Living To-Do List:

# Important

- [x]  show who has checked out which device
- [x]  create user management screen
- [x]  make error not be thrown if networkimage cant be loaded for user profile
- [x]  implement device search by checkout status
- [x]  create role system
- [x]  enforce authentication and roles
- [x]  harden app
- [x]  hide UI elements if not admin
- [x]  check in screen customization
- [x]  consolidate theme settings to profile page
- [x]  add verify email check
- [x]  show selected org name on app bar
- [x]  improve error handling on image for profile
- [x]  add auth email verification method for denying requests
- [x]  add org settings page
- [x]  add backend components for org background image
- [x]  rewrite user creation logic without blocking function
- [x]  add backend components for clean org deletion (make sure to delete user auth claims for that org THERE IS A MAX CLAIM SIZE)
- [x]  try and account for the case where front end is fetching deleted user, orgs, or devices
- [x]  add user deletion for org side
- [x]  add global user deletion from end user side
- [x]  add device deletion
- [x]  fix email verification logic to propogate to front  end faster
- [x]  properly clean user custom claims upon doing org deletion
- [x]  add backend components for org name change
- [x]  default to dark mode
- [x]  make sure all text controllers are handled properly as stateful
- [x]  make sure all async buttons use custom async button widget
- [x]  implement desk station role
    - [x]  be able to check out users other then yourself on device list
    - [x]  be able to check out users other then yourself on checkout page
    - [x]  limit users from checking out devices for other users without proper role in frontend
    - [x]  limit users from checking out devices for other users without proper role in backend
        - [x]  update_device_checkout_status_callable
    - [x]  add desk station to role selector
    - [x]  add backend role change logic for role selector
    - [x]  limit UI screens for desk station(done kinda)
- [x]  add user email to org member screen
- [x]  add device dialog box
- [x]  add mass user add via csv
- [x]  add csv template download
- [ ]  sanitize user photo url submissions
- [x]  limit members abilities to check in devices for other users

# Not super important

- [x]  limit an global profile to 10 orgs for auth claim limit in front end for org creation
- [x]  limit a global profile to 10 orgs in back end for org creation
- [x]  limit a global profile to 10 orgs in backend for org member creation
- [x]  add additional buttons to the checkout page for clarity
- [ ]  email invites/better handle password resets
- [ ]  store theme options on db
- [ ]  convert checkout logic to list of events for logging instead of directly editing objects
- [ ]  fully implement iOS and Android
- [ ]  SAML?
- [ ]  SCIM?
- [ ]  Admin definineable serial syntax checking


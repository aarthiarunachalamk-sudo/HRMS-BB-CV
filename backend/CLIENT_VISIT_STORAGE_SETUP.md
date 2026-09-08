# Dedicated Client Visit storage

Client Visit records are stored only in the `client_visits_*` database tables.
They do not use attendance, approval, employee-document, or other HRMS media
tables.

Client Visit media requires a separate Cloudinary product environment. Add
these variables to Render:

```
CLIENT_VISIT_CLOUDINARY_CLOUD_NAME=<separate cloud name>
CLIENT_VISIT_CLOUDINARY_API_KEY=<separate API key>
CLIENT_VISIT_CLOUDINARY_API_SECRET=<separate API secret>
CLIENT_VISIT_CLOUDINARY_FOLDER=hrms-client-visits
```

The dedicated cloud name must differ from `CLOUDINARY_CLOUD_NAME`. The upload
endpoint deliberately returns an error instead of falling back to existing
HRMS storage when the dedicated configuration is missing or reused.

Within the dedicated account, files are separated further as:

```
hrms-client-visits/<visit-id>/<check_in|proof|document|signature|expense>/
```

from .settings import *  # noqa: F403

# Use a file-backed SQLite DB for local development so migrations persist
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

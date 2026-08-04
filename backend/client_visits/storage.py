import cloudinary
import cloudinary.uploader
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured


def client_visit_storage_config():
    config = dict(getattr(settings, 'CLIENT_VISIT_CLOUDINARY_STORAGE', {}) or {})
    required = ('cloud_name', 'api_key', 'api_secret')
    missing = [key for key in required if not str(config.get(key) or '').strip()]
    if missing:
        raise ImproperlyConfigured(
            'Dedicated Client Visit Cloudinary storage is not configured. '
            f"Missing: {', '.join(missing)}."
        )
    primary_cloud = str(cloudinary.config().cloud_name or '').strip()
    visit_cloud = str(config['cloud_name']).strip()
    if primary_cloud and visit_cloud == primary_cloud:
        raise ImproperlyConfigured(
            'Client Visit Cloudinary must use a different cloud name from '
            'the existing HRMS Cloudinary account.'
        )
    config['folder'] = str(config.get('folder') or 'hrms-client-visits').strip('/')
    return config


def upload_client_visit_file(file, *, visit_id, category):
    config = client_visit_storage_config()
    folder = f"{config['folder']}/{visit_id}/{category}"
    result = cloudinary.uploader.upload(
        file,
        cloud_name=config['cloud_name'],
        api_key=config['api_key'],
        api_secret=config['api_secret'],
        folder=folder,
        resource_type='auto',
        use_filename=True,
        unique_filename=True,
        tags=['hrms-client-visit', str(visit_id), str(category)],
    )
    return result, config['cloud_name'], folder

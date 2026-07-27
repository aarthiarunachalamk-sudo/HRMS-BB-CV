import cloudinary.models
from django.db import migrations


DOCUMENT_FIELDS = (
    'doc_aadhar',
    'doc_pan',
    'doc_bank_passbook',
    'doc_10th',
    'doc_12th',
    'doc_degree',
    'doc_consolidated',
    'doc_college_noc',
    'doc_resume',
    'doc_experience_cert',
    'doc_relieving',
    'doc_salary_slips',
    'doc_passport_copy',
    'doc_driving',
    'doc_vaccination',
)


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0033_employeeaccount_user_and_leadership_backfill'),
    ]

    operations = [
        migrations.AlterField(
            model_name='employeeregistration',
            name=field_name,
            field=cloudinary.models.CloudinaryField(
                blank=True,
                max_length=255,
                null=True,
                resource_type='auto',
                verbose_name='file',
            ),
        )
        for field_name in DOCUMENT_FIELDS
    ]

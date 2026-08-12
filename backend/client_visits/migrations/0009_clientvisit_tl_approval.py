from django.db import migrations, models


def backfill_tl_approvals(apps, schema_editor):
    ClientVisit = apps.get_model('client_visits', 'ClientVisit')
    User = apps.get_model('hrms', 'User')
    tl_user_ids = set(
        User.objects.filter(role__in=('manager', 'tl')).values_list(
            'user_id',
            flat=True,
        )
    )
    visits = ClientVisit.objects.filter(
        status='approved',
        office_check_out_at__isnull=True,
        approved_by__in=tl_user_ids,
    )
    for visit in visits.iterator():
        visit.status = 'pending'
        visit.tl_approval_comment = visit.approval_comment
        visit.tl_approved_by = visit.approved_by
        visit.tl_approved_at = visit.approved_at
        visit.approval_comment = ''
        visit.approved_by = ''
        visit.approved_at = None
        visit.save(update_fields=[
            'status',
            'tl_approval_comment',
            'tl_approved_by',
            'tl_approved_at',
            'approval_comment',
            'approved_by',
            'approved_at',
        ])


class Migration(migrations.Migration):

    dependencies = [
        ('client_visits', '0008_clientvisitjourney_journeylocationpoint_journeystop_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='clientvisit',
            name='tl_approval_comment',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='clientvisit',
            name='tl_approved_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='clientvisit',
            name='tl_approved_by',
            field=models.CharField(blank=True, db_index=True, max_length=20),
        ),
        migrations.RunPython(backfill_tl_approvals, migrations.RunPython.noop),
    ]

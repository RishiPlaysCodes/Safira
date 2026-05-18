import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('alerts', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='NotificationLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('channel', models.CharField(choices=[('sms', 'SMS'), ('call', 'Phone Call'), ('push', 'Push Notification'), ('email', 'Email')], max_length=20)),
                ('recipient', models.CharField(max_length=100)),
                ('message', models.TextField()),
                ('status', models.CharField(choices=[('simulated', 'Simulated'), ('queued', 'Queued'), ('sent', 'Sent'), ('failed', 'Failed')], default='simulated', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('alert', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notification_logs', to='alerts.emergencyalert')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]

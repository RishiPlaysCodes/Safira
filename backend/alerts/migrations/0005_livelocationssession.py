from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('alerts', '0004_emergencyalert_ambulance_requested_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='LiveLocationSession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('session_id', models.CharField(db_index=True, max_length=200, unique=True)),
                ('status', models.CharField(choices=[('active', 'Active'), ('stopped', 'Stopped'), ('emergency', 'Emergency')], default='active', max_length=20)),
                ('latitude', models.FloatField(default=0)),
                ('longitude', models.FloatField(default=0)),
                ('speed_kmh', models.FloatField(default=0)),
                ('last_updated', models.DateTimeField(auto_now=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='live_sessions', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-last_updated'],
            },
        ),
    ]

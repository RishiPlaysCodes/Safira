import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='EmergencyAlert',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('location', models.CharField(blank=True, max_length=220)),
                ('message', models.TextField(default='Accident-like event detected. Please check immediately.')),
                ('severity', models.CharField(choices=[('low', 'Low Suspicion'), ('medium', 'Medium Suspicion'), ('high', 'High Suspicion'), ('confirmed', 'User Confirmed Accident')], default='medium', max_length=20)),
                ('source', models.CharField(choices=[('demo', 'Demo/Simulation'), ('speed_drop', 'Speed Drop'), ('impact', 'Impact/Jerk'), ('manual', 'Manual SOS')], default='demo', max_length=20)),
                ('is_cancelled', models.BooleanField(default=False)),
                ('alert_sent', models.BooleanField(default=False)),
                ('parent_call_requested', models.BooleanField(default=False)),
                ('notes', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='EmergencyContact',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('contact_name', models.CharField(max_length=100)),
                ('contact_phone', models.CharField(max_length=15)),
                ('relationship', models.CharField(blank=True, max_length=50)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]

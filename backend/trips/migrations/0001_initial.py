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
            name='Trip',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('speed', models.IntegerField(help_text='Speed in km/h')),
                ('speed_limit', models.IntegerField(default=40)),
                ('location', models.CharField(blank=True, max_length=120)),
                ('road_type', models.CharField(choices=[('normal', 'Normal Road'), ('school', 'School Zone'), ('hospital', 'Hospital Zone'), ('market', 'Market/Crowded Area'), ('highway', 'Highway')], default='normal', max_length=20)),
                ('helmet_worn', models.BooleanField(default=True)),
                ('red_light_crossed', models.BooleanField(default=False)),
                ('harsh_braking', models.BooleanField(default=False)),
                ('sudden_acceleration', models.BooleanField(default=False)),
                ('alert_triggered', models.BooleanField(default=False)),
                ('overspeed_count', models.IntegerField(default=0)),
                ('risk_score', models.IntegerField(default=0)),
                ('notes', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]

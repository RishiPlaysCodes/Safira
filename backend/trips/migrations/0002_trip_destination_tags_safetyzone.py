from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('trips', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='trip',
            name='destination',
            field=models.CharField(blank=True, max_length=160),
        ),
        migrations.AddField(
            model_name='trip',
            name='tags',
            field=models.CharField(blank=True, max_length=220),
        ),
        migrations.CreateModel(
            name='SafetyZone',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=120)),
                ('zone_type', models.CharField(choices=[('school', 'School Zone'), ('hospital', 'Hospital Zone'), ('market', 'Market/Crowded Area'), ('danger', 'Danger Zone')], max_length=20)),
                ('latitude', models.FloatField()),
                ('longitude', models.FloatField()),
                ('radius_meters', models.IntegerField(default=250)),
                ('active', models.BooleanField(default=True)),
            ],
        ),
    ]

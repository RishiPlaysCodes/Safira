from django import forms
from .models import Trip

WIDGET_ATTRS = {'class': 'form-input'}

class TripForm(forms.ModelForm):
    class Meta:
        model = Trip
        fields = [
            'speed', 'speed_limit', 'location', 'road_type',
            'helmet_worn', 'red_light_crossed', 'harsh_braking',
            'sudden_acceleration', 'notes'
        ]
        widgets = {
            'speed': forms.NumberInput(attrs={**WIDGET_ATTRS, 'placeholder': 'Current speed in km/h'}),
            'speed_limit': forms.NumberInput(attrs={**WIDGET_ATTRS, 'placeholder': 'Default 40'}),
            'location': forms.TextInput(attrs={**WIDGET_ATTRS, 'placeholder': 'e.g. Rohini, Delhi'}),
            'road_type': forms.Select(attrs=WIDGET_ATTRS),
            'helmet_worn': forms.CheckboxInput(attrs={'class': 'form-check'}),
            'red_light_crossed': forms.CheckboxInput(attrs={'class': 'form-check'}),
            'harsh_braking': forms.CheckboxInput(attrs={'class': 'form-check'}),
            'sudden_acceleration': forms.CheckboxInput(attrs={'class': 'form-check'}),
            'notes': forms.Textarea(attrs={**WIDGET_ATTRS, 'rows': 3, 'placeholder': 'Optional notes for report/demo'}),
        }

    def clean_speed(self):
        speed = self.cleaned_data['speed']
        if speed < 0:
            raise forms.ValidationError('Speed cannot be negative.')
        if speed > 250:
            raise forms.ValidationError('Speed looks unrealistic for this demo.')
        return speed

from django import forms
from django.contrib.auth.models import User
from .models import DriverProfile

WIDGET_ATTRS = {'class': 'form-input'}

class SignupForm(forms.ModelForm):
    password = forms.CharField(widget=forms.PasswordInput(attrs=WIDGET_ATTRS))
    phone_number = forms.CharField(max_length=15, widget=forms.TextInput(attrs=WIDGET_ATTRS))
    vehicle_type = forms.ChoiceField(choices=DriverProfile.VEHICLE_CHOICES, widget=forms.Select(attrs=WIDGET_ATTRS))
    license_number = forms.CharField(max_length=30, required=False, widget=forms.TextInput(attrs=WIDGET_ATTRS))
    role = forms.ChoiceField(choices=DriverProfile.ROLE_CHOICES, widget=forms.Select(attrs=WIDGET_ATTRS))

    class Meta:
        model = User
        fields = ['username', 'email', 'password']
        widgets = {
            'username': forms.TextInput(attrs=WIDGET_ATTRS),
            'email': forms.EmailInput(attrs=WIDGET_ATTRS),
        }

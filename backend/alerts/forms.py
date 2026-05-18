from django import forms
from .models import EmergencyContact

WIDGET_ATTRS = {'class': 'form-input'}

class EmergencyContactForm(forms.ModelForm):
    class Meta:
        model = EmergencyContact
        fields = ['contact_name', 'contact_phone', 'relationship']
        widgets = {
            'contact_name': forms.TextInput(attrs={**WIDGET_ATTRS, 'placeholder': 'Parent/guardian name'}),
            'contact_phone': forms.TextInput(attrs={**WIDGET_ATTRS, 'placeholder': 'Emergency phone number'}),
            'relationship': forms.TextInput(attrs={**WIDGET_ATTRS, 'placeholder': 'Mother/Father/Guardian'}),
        }

    def clean_contact_phone(self):
        phone = self.cleaned_data['contact_phone'].strip()
        if len(phone) < 8:
            raise forms.ValidationError('Enter a valid phone number.')
        return phone

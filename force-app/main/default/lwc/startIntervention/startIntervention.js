import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import startIntervention from '@salesforce/apex/InterventionController.startIntervention';

export default class StartIntervention extends LightningElement {
    @api recordId;
    state = 'idle'; // idle | locating | done
    address;
    errorMessage;

    get isIdle() { return this.state === 'idle'; }
    get isLocating() { return this.state === 'locating'; }
    get isDone() { return this.state === 'done'; }
    get canStart() { return this.state === 'idle'; }
    get addressLabel() { return this.address || 'not available (position saved)'; }

    async handleStart() {
        this.errorMessage = undefined;
        this.state = 'locating';
        try {
            const { latitude, longitude } = await this.currentPosition();
            const result = await startIntervention({ appointmentId: this.recordId, latitude, longitude });
            this.address = result.address;
            this.state = 'done';
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({ title: 'Intervention started', message: result.address || '', variant: 'success' }));
        } catch (error) {
            this.state = 'idle';
            this.errorMessage = error?.body?.message || error?.message || 'Could not start the intervention.';
        }
    }

    // Field Service mobile app: native location service. Desktop or mobile browser: browser geolocation.
    currentPosition() {
        const mobile = getLocationService();
        if (mobile && mobile.isAvailable()) {
            return mobile
                .getCurrentPosition({ enableHighAccuracy: true })
                .then((r) => ({ latitude: r.coords.latitude, longitude: r.coords.longitude }));
        }
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Location is not available on this device.'));
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (p) => resolve({ latitude: p.coords.latitude, longitude: p.coords.longitude }),
                () => reject(new Error('Location permission denied.')),
                { enableHighAccuracy: true, timeout: 15000 }
            );
        });
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}

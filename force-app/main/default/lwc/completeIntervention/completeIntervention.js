import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import completeIntervention from '@salesforce/apex/CompleteInterventionController.completeIntervention';

export default class CompleteIntervention extends LightningElement {
    @api recordId;
    workSummary = '';
    customerName = '';
    state = 'idle'; // idle | saving | done
    errorMessage;

    get isSaving() { return this.state === 'saving'; }
    get isDone() { return this.state === 'done'; }
    get canSubmit() { return this.state === 'idle'; }

    handleSummary(event) { this.workSummary = event.target.value; }
    handleName(event) { this.customerName = event.target.value; }

    signature(who) {
        return this.template.querySelector(`c-signature-pad[data-who="${who}"]`).toDataUrl();
    }

    async handleComplete() {
        this.errorMessage = undefined;
        const technicianSignature = this.signature('technician');
        const customerSignature = this.signature('customer');
        if (!this.customerName || !technicianSignature || !customerSignature) {
            this.errorMessage = 'The customer name and both signatures are required.';
            return;
        }
        this.state = 'saving';
        try {
            await completeIntervention({
                appointmentId: this.recordId,
                workSummary: this.workSummary,
                customerName: this.customerName,
                technicianSignature,
                customerSignature
            });
            this.state = 'done';
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({ title: 'Intervention completed', message: 'Service report generated.', variant: 'success' }));
        } catch (error) {
            this.state = 'idle';
            this.errorMessage = error?.body?.message || 'Could not complete the intervention.';
        }
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}

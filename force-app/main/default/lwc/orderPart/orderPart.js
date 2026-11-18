import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import orderPart from '@salesforce/apex/OrderPartController.orderPart';

export default class OrderPart extends LightningElement {
    @api recordId;
    productId;
    quantity = 1;
    needBy;
    notes = '';
    state = 'idle'; // idle | saving | done
    errorMessage;

    get isSaving() { return this.state === 'saving'; }
    get isDone() { return this.state === 'done'; }
    get canSubmit() { return this.state !== 'done'; }

    handleProduct(event) { this.productId = event.detail.recordId; }
    handleQuantity(event) { this.quantity = event.target.value; }
    handleNeedBy(event) { this.needBy = event.target.value; }
    handleNotes(event) { this.notes = event.target.value; }

    async handleOrder() {
        this.errorMessage = undefined;
        if (!this.productId || !(Number(this.quantity) > 0)) {
            this.errorMessage = 'Choose a part and a quantity.';
            return;
        }
        this.state = 'saving';
        try {
            await orderPart({
                appointmentId: this.recordId,
                productId: this.productId,
                quantity: Number(this.quantity),
                notes: this.notes,
                needBy: this.needBy || null
            });
            this.state = 'done';
            this.dispatchEvent(new ShowToastEvent({ title: 'Part requested', variant: 'success' }));
        } catch (error) {
            this.state = 'idle';
            this.errorMessage = error?.body?.message || 'Could not request the part.';
        }
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}

import { LightningElement, api } from 'lwc';

/** Finger, pen or mouse signature on a canvas. Exposes the drawing as a PNG data URL. */
export default class SignaturePad extends LightningElement {
    @api label;
    drawing = false;
    hasInk = false;

    get ctx() {
        const canvas = this.template.querySelector('canvas');
        const ctx = canvas.getContext('2d');
        ctx.lineWidth = 2.5;
        ctx.lineCap = 'round';
        ctx.strokeStyle = '#032E61';
        return ctx;
    }

    point(event) {
        const canvas = this.template.querySelector('canvas');
        const rect = canvas.getBoundingClientRect();
        return {
            x: ((event.clientX - rect.left) * canvas.width) / rect.width,
            y: ((event.clientY - rect.top) * canvas.height) / rect.height
        };
    }

    start(event) {
        this.drawing = true;
        const { x, y } = this.point(event);
        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
    }

    move(event) {
        if (!this.drawing) return;
        const { x, y } = this.point(event);
        const ctx = this.ctx;
        ctx.lineTo(x, y);
        ctx.stroke();
        this.hasInk = true;
    }

    end() {
        this.drawing = false;
    }

    @api
    clear() {
        const canvas = this.template.querySelector('canvas');
        canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
        this.hasInk = false;
    }

    /** PNG data URL, or null when nothing has been drawn. */
    @api
    toDataUrl() {
        return this.hasInk ? this.template.querySelector('canvas').toDataURL('image/png') : null;
    }
}

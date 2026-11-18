/**
 * Server side of the "Order Part" quick action: creates a Product Request with one
 * line item for the appointment's work order, so the warehouse can ship the part.
 */
public with sharing class OrderPartController {
    public class OrderResult {
        @AuraEnabled public Id productRequestId;
    }

    @AuraEnabled
    public static OrderResult orderPart(Id appointmentId, Id productId, Decimal quantity, String notes, Date needBy) {
        if (appointmentId == null || productId == null) {
            throw new AuraHandledException('Appointment and part are required.');
        }
        if (quantity == null || quantity <= 0 || quantity > 9999) {
            throw new AuraHandledException('Enter a quantity between 1 and 9999.');
        }

        ServiceAppointment sa = [
            SELECT Id, AppointmentNumber, ParentRecordId
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            WITH USER_MODE
            LIMIT 1
        ];
        Id workOrderId = sa.ParentRecordId != null && sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType
            ? sa.ParentRecordId
            : null;

        ProductRequest request = new ProductRequest(
            WorkOrderId = workOrderId,
            NeedByDate = needBy == null ? null : Datetime.newInstance(needBy, Time.newInstance(12, 0, 0, 0)),
            Description = ('Requested from ' + sa.AppointmentNumber + (String.isBlank(notes) ? '' : ': ' + notes)).left(32000),
            Status = 'Draft'
        );
        insert as user request;

        ProductRequestLineItem line = new ProductRequestLineItem(
            ParentId = request.Id,
            Product2Id = productId,
            QuantityRequested = quantity,
            WorkOrderId = workOrderId
        );
        insert as user line;

        OrderResult result = new OrderResult();
        result.productRequestId = request.Id;
        return result;
    }
}

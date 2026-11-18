@IsTest
private class OrderPartControllerTest {
    @IsTest
    static void orderCreatesRequestAndLineForTheWorkOrder() {
        System.runAs(ToolkitTestSupport.toolkitUser()) {
            Account acc = new Account(Name = 'Test Customer');
            insert acc;
            WorkOrder wo = new WorkOrder(AccountId = acc.Id, Subject = 'Printer repair');
            insert wo;
            ServiceAppointment sa = new ServiceAppointment(ParentRecordId = wo.Id, EarliestStartTime = System.now(), DueDate = System.now().addDays(1));
            insert sa;
            Product2 part = new Product2(Name = 'Fuser unit', IsActive = true);
            insert part;

            Test.startTest();
            OrderPartController.OrderResult result = OrderPartController.orderPart(sa.Id, part.Id, 2, 'Urgent', Date.today().addDays(2));
            Test.stopTest();

            ProductRequest request = [SELECT WorkOrderId, Description FROM ProductRequest WHERE Id = :result.productRequestId];
            System.assertEquals(wo.Id, request.WorkOrderId);
            System.assert(request.Description.contains('Urgent'));
            ProductRequestLineItem line = [SELECT Product2Id, QuantityRequested FROM ProductRequestLineItem WHERE ParentId = :request.Id];
            System.assertEquals(part.Id, line.Product2Id);
            System.assertEquals(2, line.QuantityRequested);
        }
    }

    @IsTest
    static void invalidQuantityIsRejected() {
        System.runAs(ToolkitTestSupport.toolkitUser()) {
            Account acc = new Account(Name = 'Test Customer');
            insert acc;
            ServiceAppointment sa = new ServiceAppointment(ParentRecordId = acc.Id, EarliestStartTime = System.now(), DueDate = System.now().addDays(1));
            insert sa;
            Product2 part = new Product2(Name = 'Fuser unit', IsActive = true);
            insert part;
            try {
                OrderPartController.orderPart(sa.Id, part.Id, 0, null, null);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assertEquals(0, [SELECT COUNT() FROM ProductRequest]);
            }
        }
    }
}

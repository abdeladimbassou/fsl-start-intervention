@IsTest
public class ToolkitTestSupport {
    // Tests run as the current user with the toolkit permission set,
    // so user-mode DML sees the toolkit's custom fields.
    public static User toolkitUser() {
        Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'Field_Service_Toolkit' LIMIT 1].Id;
        Id me = UserInfo.getUserId();
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :me AND PermissionSetId = :psId] == 0) {
            insert new PermissionSetAssignment(AssigneeId = me, PermissionSetId = psId);
        }
        return new User(Id = me);
    }
}

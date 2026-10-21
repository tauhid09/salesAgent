public with sharing class LeadSummarizer {

    // Use the same API name as in your other class
    private static final String MODEL_NAME = 'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet';

    public class Request {
        @InvocableVariable(required=true label='Lead name')
        public String leadName;
    }

    public class Result {
        @InvocableVariable(label='Summary')
        public String summary;
        @InvocableVariable(label='Error')
        public String error;
    }

    @InvocableMethod(
        label='Summarize Lead'
        description='Finds a lead by name and summarizes its status, notes and recent tasks'
    )
    public static List<Result> summarize(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request r : requests) {
            Result res = new Result();
            try {
                String key = '%' + r.leadName + '%';
                List<Lead> leads = [
                    SELECT Id, Name, Company, Title, Status, Rating, LeadSource,
                           Industry, Email, Phone, Description
                    FROM Lead
                    WHERE (Name LIKE :key OR Company LIKE :key)
                    AND IsConverted = false
                    WITH USER_MODE
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];

                if (leads.isEmpty()) {
                    res.error = 'No lead found matching: ' + r.leadName;
                    results.add(res);
                    continue;
                }

                Lead l = leads[0];
                List<Task> tasks = [
                    SELECT Subject, Status, ActivityDate
                    FROM Task
                    WHERE WhoId = :l.Id
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC
                    LIMIT 5
                ];

                String ctx = 'Lead: ' + l.Name
                    + '\nCompany: ' + l.Company
                    + '\nTitle: ' + l.Title
                    + '\nStatus: ' + l.Status
                    + '\nRating: ' + l.Rating
                    + '\nSource: ' + l.LeadSource
                    + '\nIndustry: ' + l.Industry
                    + '\nDescription: ' + l.Description
                    + '\nRecent tasks:';
                for (Task t : tasks) {
                    ctx += '\n- ' + t.Subject + ' (' + t.Status + ', due ' + t.ActivityDate + ')';
                }

                aiplatform.ModelsAPI.createGenerations_Request req =
                    new aiplatform.ModelsAPI.createGenerations_Request();
                req.modelName = MODEL_NAME;

                aiplatform.ModelsAPI_GenerationRequest body =
                    new aiplatform.ModelsAPI_GenerationRequest();
                body.prompt = 'You are a sales assistant. Using only the data below, write a short '
                    + 'summary: who the lead is, current status, how engaged they seem, and a recommended '
                    + 'next step. Max 5 bullets.\n\n' + ctx;
                req.body = body;

                aiplatform.ModelsAPI.createGenerations_Response resp =
                    new aiplatform.ModelsAPI().createGenerations(req);

                res.summary = resp.Code200.generation.generatedText;
            } catch (Exception e) {
                res.error = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
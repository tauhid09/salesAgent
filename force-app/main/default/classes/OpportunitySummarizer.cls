public with sharing class OpportunitySummarizer {

    // Use the same API name you used in ClaudeSummarizer
    private static final String MODEL_NAME = 'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet';

    public class Request {
        @InvocableVariable(required=true label='Opportunity name')
        public String opportunityName;
    }

    public class Result {
        @InvocableVariable(label='Summary')
        public String summary;
        @InvocableVariable(label='Error')
        public String error;
    }

    @InvocableMethod(
        label='Summarize Opportunity'
        description='Finds an opportunity by name and summarizes its status, notes and recent tasks'
    )
    public static List<Result> summarize(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request r : requests) {
            Result res = new Result();
            try {
                String key = '%' + r.opportunityName + '%';
                List<Opportunity> opps = [
                    SELECT Id, Name, StageName, Amount, CloseDate, NextStep, Description, Account.Name
                    FROM Opportunity
                    WHERE Name LIKE :key
                    WITH USER_MODE
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];

                if (opps.isEmpty()) {
                    res.error = 'No opportunity found matching: ' + r.opportunityName;
                    results.add(res);
                    continue;
                }

                Opportunity o = opps[0];
                List<Task> tasks = [
                    SELECT Subject, Status, ActivityDate
                    FROM Task
                    WHERE WhatId = :o.Id
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC
                    LIMIT 5
                ];

                String ctx = 'Opportunity: ' + o.Name
                    + '\nAccount: ' + (o.Account != null ? o.Account.Name : 'n/a')
                    + '\nStage: ' + o.StageName
                    + '\nAmount: ' + o.Amount
                    + '\nClose date: ' + o.CloseDate
                    + '\nNext step: ' + o.NextStep
                    + '\nDescription: ' + o.Description
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
                    + 'summary: current status, risks, and a recommended next step. Max 5 bullets.\n\n' + ctx;
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
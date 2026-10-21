public with sharing class ClaudeSummarizer {

    private static final String MODEL_NAME = 'sfdc_ai__DefaultBedrockAnthropicClaude46Sonnet';

    public class Request {
        @InvocableVariable(required=true label='Text to summarize')
        public String inputText;
    }

    public class Result {
        @InvocableVariable(label='Summary')
        public String summary;
        @InvocableVariable(label='Error')
        public String error;
    }

    @InvocableMethod(
        label='Summarize with Claude'
        description='Summarizes the given text in 3 short bullets using an AI model'
    )
    public static List<Result> summarize(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request r : requests) {
            Result res = new Result();
            try {
                aiplatform.ModelsAPI.createGenerations_Request req =
                    new aiplatform.ModelsAPI.createGenerations_Request();
                req.modelName = MODEL_NAME;

                aiplatform.ModelsAPI_GenerationRequest body =
                    new aiplatform.ModelsAPI_GenerationRequest();
                body.prompt = 'Summarize the following text in 3 short bullets:\n' + r.inputText;
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
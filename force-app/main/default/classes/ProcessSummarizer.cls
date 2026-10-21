public with sharing class ProcessSummarizer {

    private static final String MODEL_NAME = 'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet';

    public class Request {
        @InvocableVariable(required=true label='Process type' description='Sales or Lead')
        public String processType;
    }

    public class Result {
        @InvocableVariable(label='Summary')
        public String summary;
        @InvocableVariable(label='Error')
        public String error;
    }

    @InvocableMethod(
        label='Summarize Process'
        description='Summarizes the live Sales (opportunity) or Lead process: stages, volumes, bottlenecks and next steps'
    )
    public static List<Result> summarize(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request r : requests) {
            Result res = new Result();
            try {
                String type = String.isBlank(r.processType) ? '' : r.processType.toLowerCase();
                String ctx;
                String subject;

                if (type.contains('lead')) {
                    ctx = buildLeadContext();
                    subject = 'lead process';
                } else if (type.contains('sales') || type.contains('opportunity')) {
                    ctx = buildSalesContext();
                    subject = 'sales process';
                } else {
                    res.error = 'Please specify either "Sales" or "Lead" process.';
                    results.add(res);
                    continue;
                }

                res.summary = generate(
                    'You are a sales operations assistant. Using only the data below, summarize the '
                    + subject + ': how the process flows, where records are piling up, any risks or '
                    + 'bottlenecks, and one recommended next step. Max 5 bullets.\n\n' + ctx
                );
            } catch (Exception e) {
                res.error = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // ---------- SALES PROCESS ----------
    private static String buildSalesContext() {
        // Process definition (ordered stages), read dynamically
        List<OpportunityStage> stages = [
            SELECT MasterLabel, SortOrder, DefaultProbability, IsClosed, IsWon
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder
        ];

        // Live volume per stage (respects the user's sharing)
        Map<String, AggregateResult> byStage = new Map<String, AggregateResult>();
        for (AggregateResult ar : [
            SELECT StageName s, COUNT(Id) c, SUM(Amount) a
            FROM Opportunity
            WITH USER_MODE
            GROUP BY StageName
        ]) {
            byStage.put((String) ar.get('s'), ar);
        }

        Integer overdue = [
            SELECT COUNT() FROM Opportunity
            WHERE IsClosed = false AND CloseDate < TODAY
            WITH USER_MODE
        ];

        String ctx = 'SALES PROCESS (stage order, probability, opportunity count, total amount):';
        for (OpportunityStage st : stages) {
            AggregateResult ar = byStage.get(st.MasterLabel);
            ctx += '\n' + st.SortOrder + '. ' + st.MasterLabel
                + ' | probability ' + st.DefaultProbability + '%'
                + ' | ' + (st.IsClosed ? (st.IsWon ? 'closed-won' : 'closed-lost') : 'open')
                + ' | count ' + (ar != null ? String.valueOf(ar.get('c')) : '0')
                + ' | amount ' + (ar != null ? String.valueOf(ar.get('a')) : '0');
        }
        ctx += '\nOpen opportunities past their close date: ' + overdue;
        return ctx;
    }

    // ---------- LEAD PROCESS ----------
    private static String buildLeadContext() {
        List<LeadStatus> statuses = [
            SELECT MasterLabel, SortOrder, IsConverted
            FROM LeadStatus
            ORDER BY SortOrder
        ];

        Map<String, Integer> byStatus = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Status s, COUNT(Id) c
            FROM Lead
            WITH USER_MODE
            GROUP BY Status
        ]) {
            byStatus.put((String) ar.get('s'), (Integer) ar.get('c'));
        }

        Integer newLast30 = [
            SELECT COUNT() FROM Lead
            WHERE CreatedDate = LAST_N_DAYS:30
            WITH USER_MODE
        ];

        String ctx = 'LEAD PROCESS (status order, lead count):';
        for (LeadStatus ls : statuses) {
            ctx += '\n' + ls.SortOrder + '. ' + ls.MasterLabel
                + (ls.IsConverted ? ' (converted)' : '')
                + ' | count ' + (byStatus.containsKey(ls.MasterLabel) ? byStatus.get(ls.MasterLabel) : 0);
        }
        ctx += '\nLeads created in the last 30 days: ' + newLast30;
        return ctx;
    }

    // ---------- MODEL CALL ----------
    private static String generate(String prompt) {
        aiplatform.ModelsAPI.createGenerations_Request req =
            new aiplatform.ModelsAPI.createGenerations_Request();
        req.modelName = MODEL_NAME;

        aiplatform.ModelsAPI_GenerationRequest body =
            new aiplatform.ModelsAPI_GenerationRequest();
        body.prompt = prompt;
        req.body = body;

        aiplatform.ModelsAPI.createGenerations_Response resp =
            new aiplatform.ModelsAPI().createGenerations(req);
        return resp.Code200.generation.generatedText;
    }
}
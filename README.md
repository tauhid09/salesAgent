# Sales Agent

Sales Agent is a Salesforce Agentforce employee agent that helps internal users with common sales work. It summarizes supplied text, looks up and summarizes leads and opportunities, and reports on the overall lead or sales process. The agent runs in the logged-in user's context and is intended to use only records that user is allowed to access.

## Capabilities

- **Text summaries:** Summarize supplied text, notes, emails, or sales-process descriptions into three short bullets.
- **Lead summaries:** Find an unconverted lead by name or company, then summarize its status, engagement, and a recommended next step. The summary can include up to five recent tasks.
- **Opportunity summaries:** Find an opportunity by name, then summarize its stage, risks, and a recommended next step. The summary can include up to five recent tasks.
- **Process summaries:** Summarize either the lead process or the sales (opportunity) process, including stage/status volumes and recommended next steps. Sales summaries include stage amounts and overdue open opportunities; lead summaries include leads created in the last 30 days. Ask for either process, or request both.

Record summaries use the most recently modified matching record. Process data and record queries run with the current user's access where supported by the Apex queries.

## Project structure

- `force-app/main/default/aiAgents/` — Agentforce agent metadata.
- `force-app/main/default/aiAuthoringBundles/` — Agent instructions, routing, and user-facing action definitions.
- `force-app/main/default/aiAgentDefinitionVersions/` — Versioned agent definition, graph, and local action schemas.
- `force-app/main/default/classes/` — Apex invocable actions for text, lead, opportunity, and process summaries.
- `config/project-scratch-def.json` — Scratch org definition.
- `scripts/` — Sample Apex and SOQL scripts.
- `sfdx-project.json` — Salesforce DX package and API configuration.

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- A Salesforce org authorized for development and deployment; scratch org creation also requires a Dev Hub.
- An org that supports the Agentforce metadata and AI model features used by this project, with the appropriate user permissions and model access enabled.
- Node.js and npm, if you want to run the project's lint and unit-test scripts.

## Authorize an org

Log in to a development org and assign it an alias:

```bash
sf org login web --alias sales-agent-dev --instance-url https://login.salesforce.com
```

For a scratch org, first authorize a Dev Hub, then create the org from the included definition:

```bash
sf org login web --set-default-dev-hub --alias sales-agent-hub
sf org create scratch --definition-file config/project-scratch-def.json --alias sales-agent-scratch --target-dev-hub sales-agent-hub --set-default
```

## Deploy

Deploy the Salesforce metadata to the authorized org:

```bash
sf project deploy start --source-dir force-app --target-org sales-agent-dev
```

Replace `sales-agent-dev` with the alias of your target org (for example, `sales-agent-scratch`). Once deployment and org-side Agentforce setup are complete, open the org:

```bash
sf org open --target-org sales-agent-dev
```

The agent's Apex actions call Salesforce's Models API. Confirm that the AI models referenced by the Apex classes are available in the target org and that the deployed agent and users have the required access before testing summaries.

## Development checks

Install the Node development dependencies, then run the checks provided by the project:

```bash
npm install
npm run lint
npm test
```

`npm test` runs the LWC Jest unit-test script. The Apex classes are in `force-app/main/default/classes/`; use Salesforce CLI and an appropriately configured org to validate Apex changes.

## Resources

- [Salesforce CLI documentation](https://developer.salesforce.com/docs/atlas.en-us/sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce VS Code Extensions](https://developer.salesforce.com/tools/vscode/)

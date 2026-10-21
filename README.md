# Sales Agent

> A Salesforce Agentforce employee agent for everyday sales work.

![Salesforce](https://img.shields.io/badge/Salesforce-Agentforce-00A1E0?logo=salesforce&logoColor=white)
![Backend](https://img.shields.io/badge/Backend-Apex-1798c1)
![AI](https://img.shields.io/badge/AI-Claude%20Sonnet-6B4FBB)

Sales Agent summarizes supplied text, looks up and summarizes leads and opportunities, and reports on the overall lead or sales process. It runs in the logged-in user's context and is intended to use only records that user is allowed to access.

> [!NOTE]
> Lead, opportunity, and lead/sales process summaries use **Anthropic Claude Sonnet 4.5** through Salesforce's Models API. The standalone free-text summarization action currently uses **Claude Sonnet 4.5**.

## Table of contents

- [Capabilities](#capabilities)
- [Prerequisites](#prerequisites)
- [Get started](#get-started)
- [Development checks](#development-checks)
- [Project structure](#project-structure)
- [Resources](#resources)

## Capabilities

| Action                  | What it does                                                                                                                                                                                                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Text summary**        | Turns supplied text, notes, emails, or sales-process descriptions into three short bullets.                                                                                                                                                                              |
| **Lead summary**        | Finds an unconverted lead by name or company and summarizes status, engagement, and a recommended next step. May include up to five recent tasks.                                                                                                                        |
| **Opportunity summary** | Finds an opportunity by name and summarizes its stage, risks, and a recommended next step. May include up to five recent tasks.                                                                                                                                          |
| **Process summary**     | Summarizes the lead or sales (opportunity) process with stage/status volumes and recommended next steps. Sales summaries include stage amounts and overdue open opportunities; lead summaries include leads created in the last 30 days. Ask for either process or both. |

Record summaries use the most recently modified matching record. Process data and record queries run with the current user's access where supported by the Apex queries.

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- A Salesforce org authorized for development and deployment. Creating a scratch org also requires a Dev Hub.
- An org that supports the Agentforce metadata and AI model features used by this project, with the appropriate user permissions and model access enabled.
- Node.js and npm to run the lint and unit-test scripts.

## Get started

### 1. Authorize a Salesforce org

Log in to a development org and assign it an alias:

```bash
sf org login web --alias sales-agent-dev --instance-url https://login.salesforce.com
```

To use a scratch org, authorize a Dev Hub and create the org from the included definition:

```bash
sf org login web --set-default-dev-hub --alias sales-agent-hub
sf org create scratch --definition-file config/project-scratch-def.json --alias sales-agent-scratch --target-dev-hub sales-agent-hub --set-default
```

### 2. Deploy the project

Deploy the Salesforce metadata to your authorized org:

```bash
sf project deploy start --source-dir force-app --target-org sales-agent-dev
```

Replace `sales-agent-dev` with your target org alias, such as `sales-agent-scratch`. After deployment and org-side Agentforce setup, open the org:

```bash
sf org open --target-org sales-agent-dev
```

The agent's Apex actions call Salesforce's Models API. Confirm that the models referenced by the Apex classes are available in the target org and that the deployed agent and users have the required access before testing summaries.

## Development checks

Install the Node development dependencies, then run the available checks:

```bash
npm install
npm run lint
npm test
```

`npm test` runs the LWC Jest unit-test script. The Apex classes are in `force-app/main/default/classes/`; validate Apex changes with Salesforce CLI and an appropriately configured org.

## Project structure

| Path                                                | Description                                                               |
| --------------------------------------------------- | ------------------------------------------------------------------------- |
| `force-app/main/default/aiAgents/`                  | Agentforce agent metadata                                                 |
| `force-app/main/default/aiAuthoringBundles/`        | Agent instructions, routing, and user-facing action definitions           |
| `force-app/main/default/aiAgentDefinitionVersions/` | Versioned agent definition, graph, and local action schemas               |
| `force-app/main/default/classes/`                   | Apex invocable actions for text, lead, opportunity, and process summaries |
| `config/project-scratch-def.json`                   | Scratch org definition                                                    |
| `scripts/`                                          | Sample Apex and SOQL scripts                                              |
| `sfdx-project.json`                                 | Salesforce DX package and API configuration                               |

## Resources

- [Salesforce CLI documentation](https://developer.salesforce.com/docs/atlas.en-us/sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce VS Code Extensions](https://developer.salesforce.com/tools/vscode/)

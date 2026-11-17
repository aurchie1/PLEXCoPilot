# PLEX Power Platform solution

Source for the PLEX work queue, built from [rulesv1.2.json](../buildDocuments/rulesv1.2.json) and [assignmentRulesv1.0.json](../buildDocuments/assignmentRulesv1.0.json).

| Piece | Path | Status |
|---|---|---|
| SharePoint lists | [sharepoint/Provision-PlexSite.ps1](sharepoint/Provision-PlexSite.ps1) | Written, not run |
| Enrich flow (flags + `PL_Bucket`) | [flows/EnrichClaim.flow.json](flows/EnrichClaim.flow.json) | Design spec |
| Pick-next-claim flow | [flows/PickNextClaim.flow.json](flows/PickNextClaim.flow.json) | Design spec |
| Status state machine flow | [flows/TransitionStatus.flow.json](flows/TransitionStatus.flow.json) | Design spec |
| Power App | [powerapp/README.md](powerapp/README.md) | Scaffold and Power Fx |
| Declarative Agent | [agent/](agent/) | Created, source validation passes. Not provisioned |

## How the rules map

- `PL_Bucket` (1 to 6) is computed once per claim by Enrich, first match wins, so a claim is in exactly one bucket.
- Pick-next orders by `PL_Bucket asc, DaysAssignedToRO desc, DateOfClaim asc, ClaimId asc`.
- Bucket 4 (`AwardCorrection`) is filtered to `PL_GAPerOfRecord` / `PL_AuthOfRecord`, and is open to anyone when both are empty.
- Bucket 5 AUTH is filtered to `PLEX_Users.IsAttyFeeAuthorizer`. Anyone can GAP.
- Per-bucket caps live in `PLEX_Config` (`MaxPerRequestBucket1..6`), blank until decided.

## Deploy steps

1. Run `.\sharepoint\Provision-PlexSite.ps1` against https://dvagov.sharepoint.com/sites/PLEX.
2. Build the flows from the specs and the app from the scaffold. `pac` is not installed here, so nothing is deployed.
3. Add users to `PLEX_Users`.

## Open items

- The agent's API plugin points at a placeholder URL in [agent/openapi/plex-flows.yaml](agent/openapi/plex-flows.yaml). Expose PickNextClaim and TransitionStatus as HTTP endpoints, set the server URL and auth, then re-run `wiqd agent add action` and provision.
- Copilot does not support `Action.Submit`/`Action.Execute`, so the agent asks for `requiresConcurrence` and the exclude reason in chat and uses cards to display results.
- The flow files are design specs, not importable packages.
- Per-bucket caps.

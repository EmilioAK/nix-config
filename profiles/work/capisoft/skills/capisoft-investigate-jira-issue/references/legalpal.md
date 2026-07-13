# LegalPal (`LP`) investigation reference

Read this file for an `LP-*` issue. Treat the repository's live `AGENTS.md` and
deployment files as authoritative if any value below has changed.

## Jira and repository mapping

- Use the Capisoft Jira site and project `LP` (Legal Pal). The primary board is
  board `161`.
- Treat an explicit key such as `Task: LP-360` as confirmation that the
  investigation belongs to that issue.
- Ignore the separate Ratio Jira project, even when the issue text mentions
  Ratio, until the LegalPal instructions remove that exclusion.
- Use `/home/emilio/Repos/LegalPal` as the repository root. Read its
  `AGENTS.md` before any investigation.
- Inspect `/home/emilio/Repos/LegalPal/legalpal_backend` and
  `/home/emilio/Repos/LegalPal/legalpal_frontend` as separate Git repositories.
  Other sibling directories may be worktrees or historical task artifacts;
  do not treat them as current without proving their branch and remote state.
- Production normally follows the `production` branch, but verify the remote
  branch hash and deployed image rather than assuming they match.

## AWS access

Use AWS only when it can resolve a runtime, deployment, data, or infrastructure
question.

- Profile: `Legalpal` (case-sensitive)
- Region: `eu-central-1`
- Identity check:

  ```sh
  aws sts get-caller-identity --profile Legalpal
  ```

There is intentionally no default LegalPal profile. A failed bare AWS command
does not show that LegalPal authentication is unavailable. Never substitute
`Admin`, `legalpal`, `LegalPal`, or another account.

The profile uses AWS CLI login sessions. If the explicit identity check reports
an invalid or expired session, stop and ask the user to run:

```sh
aws login --profile Legalpal --remote
```

Use scoped reads from the service implicated by the issue, commonly ECR image
metadata, RDS descriptions and metrics, CloudWatch metrics/logs, or EKS
descriptions. Do not retrieve Secrets Manager or Parameter Store values.

## Rancher-proxied Kubernetes access

Current LegalPal runbooks route Kubernetes access through Rancher. Do not treat
a direct EKS authorization failure as proof that Rancher access is broken, and
do not try alternate clusters or identities as a workaround.

- Credential file: `~/.agents/secrets/rancher.env`
- Expected variable: `BEARER_TOKEN`
- Kubeconfig: `~/.kube/legalpal`
- Common namespaces: `lp-stag` and `lp-prod`; select the environment supported
  by the issue instead of querying both by default.

Load the credential without printing it:

```sh
set -a
source "$HOME/.agents/secrets/rancher.env"
set +a
K=(kubectl --kubeconfig "$HOME/.kube/legalpal" --token="$BEARER_TOKEN")
```

Start with narrow access and deployment checks:

```sh
"${K[@]}" auth can-i get deployments -n lp-prod
"${K[@]}" get deployments -n lp-prod \
  -o 'custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.spec.replicas,IMAGE:.spec.template.spec.containers[0].image'
"${K[@]}" get pods -n lp-prod \
  -o 'custom-columns=NAME:.metadata.name,PHASE:.status.phase,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount'
```

Then scope `describe`, events filtered to the implicated object, or
`logs --since=<window>` to the workload that implements the issue. Never dump
all namespace events or logs by default. Log output can contain customer data;
search narrowly, redact the report, and do not paste unrelated lines.

Compare the live container tag or digest with the exact backend or frontend
commit. Do not conclude that current source is deployed merely because a pod is
healthy. Inspect non-secret environment values only when configuration can
explain the behavior, and never output Kubernetes Secret contents.

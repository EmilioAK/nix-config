# Capisoft Profile

This profile contains Capisoft-specific tooling and agent context. Its NixOS
layer includes AWS, Kubernetes, Rancher, Docker, and NetBird tooling for the
VPS.

## Jira task system

Use [Emilio's Tasks](https://capi-soft.atlassian.net/jira/people/712020%3A4efdc0dd-f064-49ba-a052-d53890d9f0e6/boards/887)
as the canonical view of Emilio's Capisoft work.

- Keep work tied to a real project in that project and assign it to Emilio.
- Put private or projectless work in the private `EMILIO` project.
- Do not duplicate shared-project issues into `EMILIO`.
- The board uses `(assignee = currentUser() OR project = EMILIO) ORDER BY Rank ASC`.
- Verify EMILIO privacy on **Space settings -> Access**, where it must show
  **Private access**.

Agents receive the detailed workflow through the Capisoft-scoped
[`capisoft-jira-tasks`](./skills/capisoft-jira-tasks/SKILL.md) skill. It also
documents scoped-token authentication, safe writes, status transitions, and
board coverage checks.

Terse issue prompts such as `Task: LP-360` use the separate read-only
[`capisoft-investigate-jira-issue`](./skills/capisoft-investigate-jira-issue/SKILL.md)
skill. It checks the Jira report against the current repository and, when the
cause may depend on the deployed runtime, gathers read-only AWS and
Rancher/Kubernetes evidence. It never claims, changes, or fixes the issue.

## NetBird

NetBird is installed by the Capisoft NixOS module, but authentication is local
machine state. On a fresh VPS, enroll it after install:

```sh
sudo netbird up
```

The Ubuntu backup shows the previous routing model was:

- NetBird installed a `netbird` routing table with a default route through
  `wt0`.
- Policy rules sent normal outbound traffic through that NetBird table.
- A local `netbird-public-route` service added a higher-priority rule like
  `from 89.167.112.78 lookup main`, so replies sourced from the public VPS IP
  used the Hetzner WAN route instead of the NetBird exit node.
- Public inbound was not restricted to NetBird; the WAN interface accepted
  inbound traffic directly.

The NixOS module tracks that same behavior declaratively:

- `services.netbird.useRoutingFeatures = "client"` lets NetBird manage the
  outbound client/exit-node routes.
- `netbird-public-route.service` recreates the public IPv4-source policy rule
  after NetBird starts.
- The Hetzner VPS module disables IPv6 so tools such as SSH/Git cannot bypass
  the NetBird IPv4 exit route by preferring public IPv6.
- The Hetzner VPS module marks the WAN interface as trusted in the NixOS
  firewall, so public inbound remains open while outbound still defaults to
  NetBird.

Once NetBird is connected, verify both paths:

```sh
systemctl status netbird.service netbird-public-route.service
ip rule show
ip route show table netbird
ip route get 1.1.1.1
ip route get 1.1.1.1 from "$(ip -4 -o addr show scope global | awk '!/ wt0/ {split($4, a, "/"); print a[1]; exit}')"
curl -6 https://api64.ipify.org # expected to fail/no-route
sudo iptables -S INPUT | sed -n '1,20p'
```

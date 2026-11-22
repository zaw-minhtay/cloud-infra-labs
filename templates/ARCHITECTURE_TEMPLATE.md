# Architecture NN — Title

> One or two sentences: what system this is and who it is for.

**Related lab:** [Lab NN — Title](../../labs/CATEGORY/NN-what-you-build/README.md) *(delete this line if there is none)*

## Requirements

- **Functional**
  - What the system must do, stated so it can be checked
- **Non-functional**
  - Where it runs, budget, security, traceability, availability target (say so if HA is out of scope)

## Diagram

![Architecture diagram](./diagram.png)

## Components

| Component | Tool | What it does |
|---|---|---|
| | | Its role in *this* system |

Why each tool was chosen over the alternatives: see [Key decisions and trade-offs](#key-decisions-and-trade-offs).

## Environment

*(For local designs: "Local environment" with machine, runtime resources, cluster, namespaces,
URLs, and network exposure; link to the lab's SETUP.md. For cloud designs: accounts, regions,
and networks. Delete if not relevant.)*

| Item | Value |
|---|---|
| | |

## Request / data flow

Numbered to match the arrows in the diagram.

1. ...
2. ...

## Key decisions and trade-offs

| Decision | Options considered | Chosen | Why |
|---|---|---|---|
| | | | Tie it back to a requirement |

## Security

- Who or what can access what, with which credentials, and why that is least privilege
- Secrets handling and scanning

## Scaling and reliability

**What happens when something fails**

| Failure | Effect | Recovery |
|---|---|---|
| | | |

**Backups:** what is backed up, or why nothing needs to be.

**Scaling:** how it scales, and honestly where this design stops (e.g. single node).

## Cost estimate

Rough monthly cost and the biggest cost drivers (or why it is $0).

## What I'd improve next

- What you would add with more time or budget (these often become the next labs)

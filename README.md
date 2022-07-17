Python example (micro)service
=============================

This repository is an example of a Python (micro)service, packaged as a container and shipped to a Kubernetes cluster as a helm chart.

It is assumed that AWS and ECR is used, but the pipeline can be adjusted to support other registries fairly easily.

This is by no means a copy&paste and ready-to-go setup, but definitely can act as a starting point for establishing a CI/CD solution.

# Repository overview
- `app` directory contains application code,
- `test` directory contains tests,
- `helm-chart` directory defines template for the helm-chart,
- `.gitlab-ci.yml` defines a Gitlab pipeline. Defines a full CI/CD pipeline with automated testing, packaging and deploying the app.
- `requirements.txt` defines package requirements for Python app,
- `requirements.dev.txt` defines package requirements for executing the pipeline; see more in the pipeline section,
- `values.dev.yaml` contains values for helm chart used for deployment to dev environment.

# Python application

The app is built using [FastAPI](https://fastapi.tiangolo.com/), a framework designed for building HTTP APIs with Python that works with both sync and async libraries. It requires an ASGI server to run. This project leverages Uvicorn, but there are alternatives to consider depending on the requirements: https://fastapi.tiangolo.com/deployment/manually/#run-a-server-manually-uvicorn.

It implements a simple API with two endpoints:
- `/-/health` is intended to be used as a healthcheck and serves some extra diagnostics information,
- `/api/echo` is a simple echo endpoint that requires a single query string parameter `text`. Returns what was sent to it back as a JSON.

## Running locally

There's a `run-local.sh` script that starts Uvicorn with hot reloading of the app. It can be accessed at `http://localhost:8000`.

Sample calls:
```shell
$ curl "http://localhost:8000/api/echo?text=foo"
{"text":"foo}
```

```shell
$ curl http://localhost:8000/-/health
{"status":"ok","debug":{"hostname":"mycomputer","ip":"127.0.1.1"}}
```

# Gitlab pipeline

Gitlab pipeline defines the following stages: 
- check
- test
- build
- deploy

## Check

Check makes sure the code conforms to defined standards. Defined checks include:
- enforcing code format,
- making sure the code satisfies defined linter rules.

The pipeline does not move to next stage unless all of the checks pass successfully.

## Test

Executes automated tests. The pipeline does not allow for deployments if any of these fail.

## Build

Packages the app as a Docker container and publishes it to ECR. The ECR registry is automatically created using project's name and can be accessed as
`$ECR_REPOSITORY_URL/$PROJECT_NAME`.

The image is tagged with git's commit short SHA leveraging Gitlab-provided `$CI_COMMIT_SHORT_SHA`.

It expects the following environment variables defined:
- ECR_REPOSITORY_URL - URL of base ECR repository in form of `<aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com`,
- AWS_REGION,
- AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY - AWS credentials for a user capable of interacting with ECR repositories (get auth token, create repository, read and write images).

See `Notes & ideas for improvement` section for alternatives to passing credentials.

By default `$CI_PROJECT_NAME` Gitlab-provided environment variable is used as a `$PROJECT_NAME`, but it can be changed in `.gitlab-ci.yml`.

## Deploy

Deploys the application to Kubernetes with helm. Leverages AWS CLI to generate kubeconfig that is further used by helm.

The deployment is automatic on default branch (typically `main`) and manual form any other branch.

On top of the environment variables required for build it expects the following:
- EKS_CLUSTER_NAME - name of the EKS cluster,
- K8S_NAMESPACE - namespace to deploy to, defaults to `dev` if not defined.


# Notes & ideas for improvement

1. helm-chart could be moved to a separate repo and reused across projects by leveraging a private Helm repository.
2. Gitlab pipeline can be developed further to support multiple environments and different workflows, e.g. automatically deploy to dev environment from `main` (replaces `master` to build more inclusive work environments).
3. Instead of managing AWS access credentials for CI/CD pipelines, one may decide to deploy a Gitlab worker within AWS (or even within Kubernetes) with a role having all the relevant permissions.
4. Bake a Docker+kubectl docker image instead of installing kubectl on top of plain docker image in pipeline.
5. Deployment is allowed from any branch (although it's manual for any other than default branch), but your organization may favor more strict rules. Rules must be adjusted in such cases.
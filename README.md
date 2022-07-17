Python example (micro)service
=============================

This repository is an example of a Python (micro)service, packaged as a container and shipped to a Kubernetes cluster as a helm chart.

It is assumed that AWS and ECR is used, but the pipeline can be adjusted to support other registries fairly easily.

# Repository overview
- `app` directory contains application code,
- `test` directory contains tests,
- `helm-chart` directory defines template for the helm-chart,
- `.gitlab-ci.yml` defines a Gitlab pipeline. Defines a full CI/CD pipeline with automated testing, packaging and deploying the app.
- `requirements.txt` defines package requirements for Python app,
- `requirements.dev.txt` defines package requirements for executing the pipeline; see more in the pipeline section,
- `values.dev.yaml` contains values for helm chart used for deployment to dev environment.

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

# Test

Executes automated tests. The pipeline does not allow for deployments if any of these fail.

# Build

Packages the app as a Docker container and publishes it to ECR. The ECR registry is automatically created using project's name and can be accessed as
`$ECR_REPOSITORY_URL/$PROJECT_NAME`.

The image is tagged with git's commit short SHA leveraging Gitlab-provided `$CI_COMMIT_SHORT_SHA`.

It expects the following environment variables defined:
- ECR_REPOSITORY_URL - URL of base ECR repository in form of `<aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com`,
- AWS_REGION,
- AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY - AWS credentials for a user capable of interacting with ECR repositories (get auth token, create repository, read and write images).

See `Notes & ideas for improvement` section for alternatives to passing credentials.

By default `$CI_PROJECT_NAME` Gitlab-provided environment variable is used as a `$PROJECT_NAME`, but it can be changed in `.gitlab-ci.yml`.

# Deploy

Deploys the application to Kubernetes with helm.


# Notes & ideas for improvement

1. helm-chart could be moved to a separate repo and reused across projects by leveraging a private Helm repository.
2. Gitlab pipeline can be developed further to support multiple environments and different workflows, e.g. automatically deploy to dev environment from `main` (replaces `master` to build more inclusive work environments).
3. Instead of managing AWS access credentials for CI/CD pipelines, one may decide to deploy a Gitlab worker within AWS (or even within Kubernetes) with a role having all the relevant permissions.
4. Bake a Docker+kubectl docker image instead of installing kubectl on top of plain docker image in pipeline.
---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Decision Making

Changes to this repository are first reviewed using the [merge request workflow](https://about.gitlab.com/handbook/engineering/development/enablement/systems/distribution/merge_requests.html) then merged by project maintainers.

Architectural decisions (such as those that would appear on the [architecture](architecture.md) or [decisions](decisions.md) pages) require the review of the project's senior technical leadership. Senior technical leadership are individuals identified by the Engineering Manager of the team responsible for the project, as well as that team's Staff+ leadership as mentioned in the [architecture handbook](https://about.gitlab.com/handbook/engineering/architecture/#architecture-as-a-practice-is-everyones-responsibility) and any current working group formed around a goal specific to the project.

## Maintainers

Project maintainers can be found on the [GitLab projects page](https://about.gitlab.com/handbook/engineering/projects/#gitlab-chart), or located using the [review workload dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/?currentProject=gitlab-chart&mode=hide).

Maintainers are responsible for merging changes within their domain, and having an understanding of the whole project and how changes may impact areas outside their expertise.

Reviewers can assign to any maintainer and the maintainer will engage the appropriate domain expert if it does not fall within their own.

In order to continue to expand their expertise maintainers are empowered to merge changes outside their domain but that they are **highly confident** in unless:

- The change cannot be reverted later
- The change has an established process that needs to be followed (JiHu review, security, legal/license changes)
- The change clearly requires an architectural decision

When urgent changes are required, maintainers should have a bias-for action, and can make decisions as long as the decisions are later reversible and compliant with known project process requirements.

## Project Leadership

| Username | Role |
| -- | -- |
| @WarheadsSE | Staff Engineer, Distribution Deploy |
| @twk3 | Engineering Manager, Distribution Build |
| @ayufan | Distinguished Engineer, Enablement |
| @stanhu | Engineering Fellow |

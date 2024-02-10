---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrate from the Helm chart to the Linux package **(FREE SELF)**

To migrate from a Helm installation to a Linux package (Omnibus) installation:

1. Go to the admin area (**{admin}**) and select **Overview > Components** to
   check your current version of GitLab.
1. Prepare a clean machine and
   [install the Linux package](https://docs.gitlab.com/ee/update/package/index.html)
   that matches your GitLab Helm chart version.
1. [Verify the integrity of Git repositories](https://docs.gitlab.com/ee/administration/raketasks/check.html)
   on your GitLab Helm chart instance before the migration.
1. Create [a backup of your GitLab Helm chart instance](../../backup-restore/backup.md),
   and make sure to [back up the secrets](../../backup-restore/backup.md#backup-the-secrets)
   as well.
1. Back up `/etc/gitlab/gitlab-secrets.json` on your Omnibus GitLab instance.
1. Install the [yq](https://github.com/mikefarah/yq) tool (version 4.21.1 or later) on the workstation where you run `kubectl` commands.
1. Create a copy of your `/etc/gitlab/gitlab-secrets.json` file on your workstation.
1. Run the following command to obtain the secrets from your GitLab Helm chart instance.
   Replace `GITLAB_NAMESPACE` and `RELEASE` with appropriate values:

   ```shell
   kubectl get secret -n GITLAB_NAMESPACE RELEASE-rails-secret -ojsonpath='{.data.secrets\.yml}' | yq '@base64d | from_yaml | .production' -o json > rails-secrets.json
   yq eval-all 'select(filename == "gitlab-secrets.json").gitlab_rails = select(filename == "rails-secrets.json") | select(filename == "gitlab-secrets.json")' -ojson  gitlab-secrets.json rails-secrets.json > gitlab-secrets-updated.json
   ```

1. The result is `gitlab-secrets-updated.json`, which you can use to replace the old version of `/etc/gitlab/gitlab-secrets.json`
   on your Omnibus GitLab instance.
1. After replacing `/etc/gitlab/gitlab-secrets.json`, reconfigure Omnibus GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. In the Omnibus instance, configure [object storage](https://docs.gitlab.com/ee/administration/object_storage.html),
   and make sure it works by testing LFS, artifacts, uploads, and so on.
1. If you use the Container Registry, [configure its object storage separately](https://docs.gitlab.com/ee/administration/packages/container_registry.html#use-object-storage). It does not support
   the consolidated object storage.
1. Sync the data from your object storage connected to the Helm chart instance with the new storage
   connected to Omnibus GitLab. A couple of notes:

   - For S3-compatible storages, use the `s3cmd` utility to copy the data.
   - If you plan to use an S3-compatible object storage like MinIO with your
     Omnibus GitLab instance, you should configure the options `endpoint`
     pointing to your MinIO and set `path_style` to `true` in
     `/etc/gitlab/gitlab.rb`.
   - You may re-use your old object storage with the new Omnibus GitLab instance. In this case, you
     do not need to sync data between two object storages. However, the storage could be de-provisioned when
     you uninstall GitLab Helm chart if you are using the built-in MinIO instance.

1. Copy the GitLab Helm backup to `/var/opt/gitlab/backups` on your Omnibus GitLab instance, and
   [perform the restore](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-gitlab-installations).
1. After the restore is complete, run the [doctor Rake tasks](https://docs.gitlab.com/ee/administration/raketasks/check.html)
   to make sure that the secrets are valid.
1. After everything is verified, you may [uninstall](../uninstall.md)
   the GitLab Helm chart instance.

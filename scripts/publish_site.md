## `publish_site.py` – Hugo Site Publisher

This script automates publishing a Hugo site to infrastructure created by a  Terraform component from [**aws-iac**](https://github.com/tstrall/aws-iac) (defaults to [`serverless-site`](https://github.com/tstrall/aws-iac/tree/main/components/serverless-site)).

It performs the following actions:

- Builds the site using Hugo  
- Fetches runtime settings from AWS SSM Parameter Store  
- Uploads the site content to an S3 bucket  
- Invalidates the corresponding CloudFront distribution  

---

### Usage

**Default component (`serverless-site`):**

```bash
AWS_PROFILE=dev-iac ./scripts/publish_site.py test-site
```

**Custom component:**

```bash
AWS_PROFILE=dev-iac ./scripts/publish_site.py --component some-other-component test-site
```

This will:

- Build the site using Hugo  
- Retrieve `/iac/<component>/<nickname>/runtime` from Parameter Store  
- Upload the contents of the `public/` directory to the configured S3 bucket  
- Trigger a CloudFront invalidation  
- Output the public URL if available  

---

### Runtime Configuration

The script expects the following SSM Parameter Store path to exist:

```
/iac/<component>/<nickname>/runtime
```

For example:

```
/iac/serverless-site/test-site/runtime
```

This parameter must be a JSON object with the following keys:

```json
{
  "content_bucket_prefix": "test-site.strall.com",
  "cloudfront_distribution_id": "EXAMPLEDIST12345",
  "cloudfront_distribution_domain": "d123abc456xyz.cloudfront.net"
}
```

- `content_bucket_prefix`: The S3 bucket name used for hosting the site  
- `cloudfront_distribution_id`: The ID of the CloudFront distribution to invalidate  
- `cloudfront_distribution_domain`: (Optional) Used to display the site URL after publishing  

---

### Dry Run Support

To preview S3 sync changes without modifying the bucket:

```bash
AWS_PROFILE=dev-iac ./scripts/publish_site.py test-site --dry-run
```

This will run Hugo and simulate the S3 sync using the `--dryrun` flag.

---

### Requirements

- Hugo must be installed and available on your `PATH`  
- The AWS CLI must be installed and configured  
- The appropriate AWS profile (`AWS_PROFILE`) must be set  
- The runtime config must already exist in SSM Parameter Store  
- Terraform must have deployed the corresponding infrastructure  

---

### Notes

- If `cloudfront_distribution_id` is missing, the script will exit with an error  
- If `cloudfront_distribution_domain` is missing, the script will still function, but no live URL will be shown  
- This script is intended to be run from the root of the repository  

---

Let me know if you'd like a short help output (`--help`) example added too.
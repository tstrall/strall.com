#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys

import boto3


def run(cmd, dry_run=False):
    """Run a shell command with logging and error handling."""
    print(f"▶️ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("❌ Command failed:", " ".join(cmd))
        print(result.stderr)
        if not dry_run:
            sys.exit(1)
    return result


def get_runtime(component, nickname):
    """Fetch runtime parameter from AWS SSM."""
    session = boto3.Session()
    region = session.region_name
    if not region:
        print("❌ No region set for boto3 session. Check your AWS_PROFILE.")
        sys.exit(1)

    ssm = session.client("ssm", region_name=region)
    name = f"/iac/{component}/{nickname}/runtime"

    try:
        response = ssm.get_parameter(Name=name)
    except ssm.exceptions.ParameterNotFound:
        print(f"❌ Runtime config not found at: {name}")
        sys.exit(1)

    return json.loads(response["Parameter"]["Value"])


def main():
    parser = argparse.ArgumentParser(
        description="Publish Hugo site to a deployed S3 + CloudFront target."
    )
    parser.add_argument("nickname", help="Nickname for the site (e.g. test-site)")
    parser.add_argument("--component", default="serverless-site", help="Terraform component name (default: serverless-site)")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without uploading")
    args = parser.parse_args()

    print("🔧 Building Hugo site...")
    run(["hugo"], dry_run=args.dry_run)

    print("📡 Fetching runtime config from Parameter Store...")
    runtime = get_runtime(args.component, args.nickname)

    bucket = runtime.get("content_bucket_prefix")
    dist_id = runtime.get("cloudfront_distribution_id")
    domain = runtime.get("cloudfront_distribution_domain")

    if not bucket or not dist_id:
        print("❌ Missing required fields in runtime config.")
        sys.exit(1)

    print(f"☁️ Uploading to S3 bucket: {bucket}")
    sync_cmd = ["aws", "s3", "sync", "public/", f"s3://{bucket}", "--delete"]
    if args.dry_run:
        sync_cmd.append("--dryrun")
    run(sync_cmd, dry_run=args.dry_run)

    print("🚀 Creating CloudFront invalidation...")
    run([
        "aws", "cloudfront", "create-invalidation",
        "--distribution-id", dist_id,
        "--paths", "/*"
    ], dry_run=args.dry_run)

    if domain:
        print(f"🌐 Site is live at: https://{domain}")
    else:
        print("ℹ️ CloudFront domain not found in runtime.")


if __name__ == "__main__":
    main()

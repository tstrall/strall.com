#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys

import boto3

def run(cmd):
    print(f"▶️ {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("❌ Command failed:", " ".join(cmd))
        sys.exit(1)

def get_runtime(nickname):
    ssm = boto3.client("ssm")
    name = f"/iac/serverless-site/{nickname}/runtime"
    response = ssm.get_parameter(Name=name)
    return json.loads(response["Parameter"]["Value"])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nickname", required=True, help="Nickname for the site")
    args = parser.parse_args()

    print("🔧 Building Hugo site...")
    run(["hugo"])

    print("📡 Fetching runtime from Parameter Store...")
    runtime = get_runtime(args.nickname)

    bucket = runtime.get("content_bucket_prefix")
    dist_id = runtime.get("cloudfront_distribution_id")
    domain = runtime.get("cloudfront_distribution_domain")

    if not bucket or not dist_id:
        print("❌ Missing required fields in runtime.")
        sys.exit(1)

    print(f"☁️ Uploading to S3 bucket: {bucket}")
    run(["aws", "s3", "sync", "public/", f"s3://{bucket}", "--delete"])

    print("🚀 Creating CloudFront invalidation...")
    run([
        "aws", "cloudfront", "create-invalidation",
        "--distribution-id", dist_id,
        "--paths", "/*"
    ])

    if domain:
        print(f"🌐 Site is live at: https://{domain}")
    else:
        print("ℹ️ CloudFront domain not found in runtime.")

if __name__ == "__main__":
    main()

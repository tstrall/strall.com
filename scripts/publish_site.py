#!/usr/bin/env python3

import os
import sys
import json
import argparse
import subprocess
import boto3

def run(cmd, desc):
    print(f"\n🔧 {desc}...")
    print(f"▶️ {cmd}")
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"❌ Command failed: {cmd}")
        sys.exit(result.returncode)

def get_ssm_parameter(name):
    ssm = boto3.client("ssm")
    try:
        response = ssm.get_parameter(Name=name)
        return json.loads(response["Parameter"]["Value"])
    except Exception as e:
        print(f"❌ Error fetching parameter {name}: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Build and publish Hugo site to S3 + CloudFront")
    parser.add_argument("--nickname", required=True, help="Component nickname (e.g. strall-com)")
    args = parser.parse_args()

    nickname = args.nickname
    base_path = f"/iac/serverless-site/{nickname}"

    # Step 1: Build Hugo site
    run("hugo --minify", "Building Hugo site")

    # Step 2: Fetch config and runtime
    print("📡 Fetching config from Parameter Store...")
    config = get_ssm_parameter(f"{base_path}/config")
    runtime = get_ssm_parameter(f"{base_path}/runtime")

    # Step 3: Validate expected keys
    required_config_keys = ["content_bucket_prefix", "site_name"]
    required_runtime_keys = ["bucket_name", "cloudfront_domain"]

    missing_config = [k for k in required_config_keys if k not in config]
    missing_runtime = [k for k in required_runtime_keys if k not in runtime]

    if missing_config or missing_runtime:
        print("❌ Missing required fields in config or runtime.")
        if missing_config:
            print(f"   Missing in config: {missing_config}")
        if missing_runtime:
            print(f"   Missing in runtime: {missing_runtime}")
        sys.exit(1)

    bucket = runtime["bucket_name"]
    dist_domain = runtime["cloudfront_domain"]

    # Step 4: Sync site contents to S3 (bucket must block ACLs)
    sync_cmd = f"aws s3 sync public/ s3://{bucket} --delete"
    run(sync_cmd, f"Uploading site to s3://{bucket}")

    print(f"\n✅ Published to CloudFront at: https://{dist_domain}/")

if __name__ == "__main__":
    main()

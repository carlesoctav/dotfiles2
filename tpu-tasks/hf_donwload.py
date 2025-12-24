#!/usr/bin/env python3
import os
import sys
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse
from tqdm import tqdm

from google.cloud import storage
from huggingface_hub import list_repo_files, hf_hub_url


CHUNK = 1024 * 1024  # 1 MB


def stream_one(path: str, repo: str, repo_type: str, bucket, prefix: str, hf_token: str):
    url = hf_hub_url(repo, path, repo_type=repo_type)
    headers = {"Authorization": f"Bearer {hf_token}"} if hf_token else {}

    with requests.get(url, headers=headers, stream=True, timeout=300) as r:
        r.raise_for_status()
        total = int(r.headers.get("Content-Length", 0))
        blob = bucket.blob(f"{prefix}{path}")

        with blob.open("wb") as f, tqdm(
            total=total,
            unit="B",
            unit_scale=True,
            desc=path,
            leave=False,
        ) as pbar:
            for chunk in r.iter_content(CHUNK):
                if chunk:
                    f.write(chunk)
                    pbar.update(len(chunk))


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} [repo] [gcs_path] [repo_type]")
        sys.exit(1)

    repo = sys.argv[1]
    gcs_path = sys.argv[2]
    repo_type = sys.argv[3]  # "dataset" or "model"

    if not gcs_path.startswith("gs://"):
        raise ValueError("gcs_path must start with gs://")
    parts = urlparse(gcs_path)
    bucket_name = parts.netloc
    prefix = parts.path.lstrip("/")
    if prefix and not prefix.endswith("/"):
        prefix += "/"

    hf_token = os.environ.get("HF_TOKEN")  # set if gated/private

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    files = list_repo_files(repo, repo_type=repo_type)
    print(f"Found {len(files)} files in repo {repo}")

    with tqdm(total=len(files), desc="Total files") as total_bar:
        with ThreadPoolExecutor(max_workers=8) as ex:
            futs = [ex.submit(stream_one, path, repo, repo_type, bucket, prefix, hf_token) for path in files]
            for fut in as_completed(futs):
                fut.result()
                total_bar.update(1)


if __name__ == "__main__":
    main()


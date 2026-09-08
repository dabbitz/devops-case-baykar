import requests
import os
from pymongo import MongoClient

# Configuration
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "dabbitz")
GITHUB_REPO = os.getenv("GITHUB_REPO", "devops-case-baykar")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")

MONGODB_URI = os.getenv("MONGODB_URI")
MONGODB_DB = os.getenv("MONGODB_DB", "sample_training")
MONGODB_COLLECTION = os.getenv("MONGODB_COLLECTION", "github_repositories")

# Validation
if not GITHUB_TOKEN:
    raise RuntimeError("GITHUB_TOKEN environment variable is not set.")

if not MONGODB_URI:
    raise RuntimeError("MONGODB_URI environment variable is not set.")

#GitHub API
url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}"

headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "X-GitHub-Api-Version": "2026-03-10",
}

print(f"Fetching repository: {GITHUB_OWNER}/{GITHUB_REPO}")

response = requests.get(url, headers=headers, timeout=15)
response.raise_for_status()

repo = response.json()

print(f"Github repository received: " f"{repo['full_name']} (id ={repo['id']})")

# MongoDB
client = MongoClient(MONGODB_URI)

db = client[MONGODB_DB]
collection = db[MONGODB_COLLECTION]

# Prevent duplicate repository documents
collection.create_index("github_id", unique=True)

# Transform
document = {
    "github_id": repo["id"],
    "name": repo["name"],
    "full_name": repo["full_name"],
    "description": repo["description"],
    "html_url": repo["html_url"],
    "language": repo["language"],
    "stargazers_count": repo["stargazers_count"],
    "forks_count": repo["forks_count"],
    "open_issues_count": repo["open_issues_count"],
    "default_branch": repo["default_branch"],
    "private": repo["private"],
    "updated_at": repo["updated_at"]
}

# Upsert (Insert if not exists, update if it does)
result = collection.update_one(
    {"github_id": repo['id']},
    {"$set": document},
    upsert=True
)

# Logging
if result.upserted_id is not None:
    print(f"INSERT: repository added " 
          f"(github_id={repo['id']})")
else:
    print(f"UPDATE: repository updated " 
          f"(github_id={repo['id']})")

print(f"MongoDB document count: {collection.count_documents({})}")

client.close()

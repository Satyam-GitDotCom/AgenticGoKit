import json
import time
import requests

# Test direct Ollama API call with timing breakdown
url = "http://localhost:11434/api/chat"

payload = {
    "model": "granite4:latest",
    "messages": [
        {
            "role": "user",
            "content": "will it rain in San Francisco"
        }
    ],
    "stream": False,
    "temperature": 0.0,
}

print("=== Direct Ollama API Test ===\n")
print("Request payload size:", len(json.dumps(payload)), "bytes")
print("Model: granite4:latest")
print()

# Time the full request (includes parsing)
for i in range(3):
    start = time.time()
    response = requests.post(url, json=payload)
    total = time.time() - start
    
    result = response.json()
    response_text = result.get("message", {}).get("content", "")
    
    print(f"Call {i+1}:")
    print(f"  Status: {response.status_code}")
    print(f"  Response size: {len(response_text)} bytes")
    print(f"  Total time: {total:.3f}s")
    print(f"  Request time breakdown:")
    print(f"    - Network + Server: {total:.3f}s")
    print()


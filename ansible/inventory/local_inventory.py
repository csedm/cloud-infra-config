#!/usr/bin/env python3
# roles/ansible-pull-setup/files/local_inventory.py

import json
import requests
import sys
import os

def get_token():
    """Get an IMDSv2 token"""
    token_url = "http://169.254.169.254/latest/api/token"
    headers = {"X-aws-ec2-metadata-token-ttl-seconds": "300"}
    try:
        response = requests.put(token_url, headers=headers, timeout=2)
        return response.text
    except requests.exceptions.RequestException:
        # Not running on EC2 or IMDSv2 not available
        return None

def get_metadata(path, token):
    """Get metadata from IMDSv2"""
    url = f"http://169.254.169.254/latest/meta-data/{path}"
    headers = {"X-aws-ec2-metadata-token": token}
    try:
        response = requests.get(url, headers=headers, timeout=2)
        return response.text
    except requests.exceptions.RequestException:
        return None

def main():
    # Initialize inventory structure
    inventory = {
        "_meta": {
            "hostvars": {
                "localhost": {
                    "ansible_connection": "local"
                }
            }
        },
        "localhost": {
            "hosts": ["localhost"]
        },
        "common": {
            "hosts": ["localhost"]
        }
    }
    
    # Get IMDSv2 token
    token = get_token()
    
    if token:
        # We're on EC2, get instance metadata
        instance_id = get_metadata("instance-id", token)
        if instance_id:
            inventory["_meta"]["hostvars"]["localhost"]["instance_id"] = instance_id
            
        # Try to get role tags
        try:
            roles = get_metadata("tags/instance/ansible_roles", token)
            if roles:
                roles = roles.split(',')
                inventory["_meta"]["hostvars"]["localhost"]["roles"] = roles
                
                # Add host to appropriate role groups
                for role in roles:
                    role = role.strip()
                    if role and role != "common":  # common is already added
                        if role not in inventory:
                            inventory[role] = {"hosts": []}
                        inventory[role]["hosts"].append("localhost")
        except:
            # No Role tag, just use common
            pass
    
    # Print the inventory
    print(json.dumps(inventory, indent=2))

if __name__ == "__main__":
    main()
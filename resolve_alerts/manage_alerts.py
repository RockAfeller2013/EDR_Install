#!/usr/bin/env python
"""
Carbon Black EDR - Alert Management Script using cbapi
API Documentation: https://cbapi.readthedocs.io/en/latest/response-examples/

Installation:
    pip install cbapi

Usage (with command-line credentials):
    python manage_alerts.py --url https://192.168.1.30 --token YOUR_TOKEN list
    python manage_alerts.py --url https://192.168.1.30 --token YOUR_TOKEN list --unresolved
    python manage_alerts.py --url https://192.168.1.30 --token YOUR_TOKEN resolve-all
    python manage_alerts.py --url https://192.168.1.30 --token YOUR_TOKEN resolve --alert-id <ID>

Usage (with credentials file ~/.carbonblack/credentials.response):
    python manage_alerts.py list
    python manage_alerts.py list --unresolved
    python manage_alerts.py resolve-all

Credentials file format:
    [default]
    url=https://192.168.1.30
    token=YOUR_API_TOKEN_HERE
    ssl_verify=False

To get an API token:
1. Log into Carbon Black web console
2. Go to User Management > API Keys
3. Create a new API key
"""

import sys
import argparse
import time
from cbapi.response import CbResponseAPI
from cbapi.response.models import Alert
from cbapi.errors import ServerError, ApiError


def list_alerts(cb, unresolved_only=False, query="", max_results=100):
    """List alerts with optional filtering"""
    
    print("Fetching alerts...")
    
    try:
        # Build query
        if unresolved_only:
            alert_query = cb.select(Alert).where("-status:Resolved")
        else:
            alert_query = cb.select(Alert)
        
        # Add additional query if provided
        if query:
            alert_query = alert_query.where(query)
        
        # Limit results
        alerts = list(alert_query[:max_results])
        
        if not alerts:
            print("No alerts found.")
            return
        
        print(f"\nTotal alerts found: {len(alerts)}\n")
        
        # Print header
        print(f"{'ALERT ID':<40} {'HOSTNAME':<20} {'STATUS':<15} {'ALERT TYPE':<30}")
        print("-" * 105)
        
        # Print each alert
        for alert in alerts:
            alert_id = alert.unique_id if hasattr(alert, 'unique_id') else str(alert.id)
            hostname = getattr(alert, 'hostname', 'N/A')
            status = getattr(alert, 'status', 'N/A')
            alert_type = getattr(alert, 'alert_type', 'N/A')
            
            print(f"{alert_id:<40} {hostname:<20} {status:<15} {alert_type:<30}")
        
        print()
        
    except (ServerError, ApiError) as e:
        print(f"Error fetching alerts: {e}")
        sys.exit(1)


def resolve_alert_by_id(cb, alert_id):
    """Resolve a specific alert by ID"""
    
    try:
        print(f"Resolving alert: {alert_id}")
        
        # Find the alert
        alert = cb.select(Alert).where(f"unique_id:{alert_id}").first()
        
        if not alert:
            print(f"Alert {alert_id} not found")
            return False
        
        # Update status
        alert.status = "Resolved"
        alert.save()
        
        print(f"✓ Alert {alert_id} resolved successfully")
        return True
        
    except (ServerError, ApiError) as e:
        print(f"✗ Failed to resolve alert {alert_id}: {e}")
        return False


def resolve_alerts_bulk(cb, query=""):
    """Resolve multiple alerts matching a query"""
    
    print("Fetching unresolved alerts...")
    
    try:
        # Build query for unresolved alerts
        alert_query = cb.select(Alert).where("-status:Resolved")
        
        if query:
            alert_query = alert_query.where(query)
        
        # Get count
        alert_count = len(alert_query)
        
        if alert_count == 0:
            print("No unresolved alerts found.")
            return
        
        print(f"Found {alert_count} unresolved alert(s)")
        
        # Confirm
        response = input(f"Are you sure you want to resolve all {alert_count} alerts? (yes/no): ")
        if response.lower() != "yes":
            print("Operation cancelled.")
            return
        
        print("\nResolving alerts...")
        
        # Use bulk operation
        alert_query.change_status("Resolved")
        
        # Wait for changes to take effect
        print("Waiting for changes to take effect...")
        time.sleep(5)
        
        print(f"✓ Successfully resolved {alert_count} alerts")
        
    except (ServerError, ApiError) as e:
        print(f"Error during bulk resolution: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Carbon Black EDR Alert Management using cbapi",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using command-line credentials:
  %(prog)s --url https://192.168.1.30 --token YOUR_TOKEN list
  %(prog)s --url https://192.168.1.30 --token YOUR_TOKEN --no-ssl-verify list --unresolved
  %(prog)s --url https://192.168.1.30 --token YOUR_TOKEN resolve-all
  
  # Using credentials file:
  %(prog)s list
  %(prog)s list --unresolved
  %(prog)s resolve-all
  %(prog)s resolve --alert-id abc123-def456-789
        """
    )
    
    # Global connection arguments
    parser.add_argument('--url', type=str, 
                       help='Carbon Black server URL (e.g., https://192.168.1.30)')
    parser.add_argument('--token', type=str,
                       help='API authentication token')
    parser.add_argument('--no-ssl-verify', action='store_true',
                       help='Disable SSL certificate verification')
    parser.add_argument('--profile', type=str, default='default',
                       help='Credentials profile to use from config file (default: default)')
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List alerts')
    list_parser.add_argument('--unresolved', action='store_true', 
                            help='Show only unresolved alerts')
    list_parser.add_argument('--query', type=str, default='',
                            help='Additional query filter (e.g., "hostname:server01")')
    list_parser.add_argument('--max', type=int, default=100,
                            help='Maximum number of results (default: 100)')
    
    # Resolve-all command
    resolve_all_parser = subparsers.add_parser('resolve-all', 
                                               help='Resolve all unresolved alerts')
    resolve_all_parser.add_argument('--query', type=str, default='',
                                   help='Additional query filter to limit which alerts to resolve')
    
    # Resolve command
    resolve_parser = subparsers.add_parser('resolve', help='Resolve specific alert(s)')
    resolve_parser.add_argument('--alert-id', type=str,
                               help='Specific alert ID to resolve')
    resolve_parser.add_argument('--query', type=str, default='',
                               help='Query to match alerts to resolve')
    
    args = parser.parse_args()
    
    # Show help if no command provided
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Initialize Carbon Black API
    try:
        # Use command-line credentials if provided
        if args.url and args.token:
            print(f"Connecting to Carbon Black EDR at {args.url}...")
            cb = CbResponseAPI(
                url=args.url,
                token=args.token,
                ssl_verify=not args.no_ssl_verify
            )
        else:
            # Fall back to credentials file
            if args.url or args.token:
                print("Error: Both --url and --token must be provided together")
                sys.exit(1)
            
            print(f"Connecting to Carbon Black EDR (profile: {args.profile})...")
            cb = CbResponseAPI(profile=args.profile)
        
        print("✓ Connected successfully\n")
        
    except Exception as e:
        print(f"Error connecting to Carbon Black: {e}")
        print("\nYou can provide credentials in two ways:")
        print("\n1. Command-line arguments:")
        print("   python manage_alerts.py --url https://192.168.1.30 --token YOUR_TOKEN --no-ssl-verify list")
        print("\n2. Credentials file at ~/.carbonblack/credentials.response:")
        print("   [default]")
        print("   url=https://192.168.1.30")
        print("   token=YOUR_API_TOKEN")
        print("   ssl_verify=False")
        sys.exit(1)
    
    # Execute command
    try:
        if args.command == 'list':
            list_alerts(cb, args.unresolved, args.query, args.max)
        
        elif args.command == 'resolve-all':
            resolve_alerts_bulk(cb, args.query)
        
        elif args.command == 'resolve':
            if args.alert_id:
                resolve_alert_by_id(cb, args.alert_id)
            elif args.query:
                resolve_alerts_bulk(cb, args.query)
            else:
                print("Error: Must provide either --alert-id or --query")
                sys.exit(1)
    
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user")
        sys.exit(0)


if __name__ == "__main__":
    main()

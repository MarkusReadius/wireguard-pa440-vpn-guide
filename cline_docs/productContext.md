# WireGuard Site-to-Site VPN Guide

## Purpose
This guide provides comprehensive instructions for setting up a multi-site WireGuard VPN configuration in a virtualized environment with Palo Alto Networks PA-440 firewalls.

## Problem Statement
Organizations need to:
- Securely connect multiple sites using WireGuard VPN
- Deploy the solution behind PA-440 firewalls
- Test the configuration in environments with limited internet access
- Maintain consistent network segmentation across sites

## Solution Overview
A detailed, step-by-step guide for implementing a 3-4 site WireGuard VPN configuration with:
- Virtualized Ubuntu servers on ESXi
- PA-440 firewall integration at each site
- Support for testing with limited internet connectivity
- Clear network addressing scheme

## Network Design
- Site 1: 10.83.10.0/24
- Site 2: 10.83.20.0/24
- Site 3 (potential): 10.83.30.0/24
- HQ: 10.83.40.0/24

## Key Requirements
1. Must be "dummy proof" - clear, concise instructions
2. Must support testing with single internet-connected PA-440
3. Must be deployable on ESXi virtualized environment
4. Must maintain secure connectivity between all sites

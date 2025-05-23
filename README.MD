# check-aws-orphan.sh

A Bash script to identify and report orphaned AWS EC2 snapshots—snapshots that are no longer associated with any Amazon Machine Images (AMIs). Orphaned snapshots can accumulate over time, leading to unnecessary storage costs. This script aids in pinpointing such snapshots for potential cleanup.

## Features

- **Identification of Orphaned Snapshots**: Lists all EC2 snapshots in your AWS account that are not linked to any AMIs.
- **Cost Optimization**: Helps in reducing AWS storage costs by identifying unused snapshots.
- **Automation Friendly**: Can be integrated into cron jobs or CI/CD pipelines for regular monitoring.

## Prerequisites

- **AWS CLI**: Ensure that the AWS Command Line Interface is installed and configured with appropriate permissions.
- **Bash Shell**: The script is written in Bash and requires a Unix-like environment.
- **CDP CLI**: Ensure that the Cloudera CDP Command Line Interface is installed and configured with appropriate permissions.
- **jq**: Ensure that the jq is installed and configured with appropriate permissions.

## Usage

1. **Clone the Repository**:

```bash
git clone https://github.com/nicknameyu/cdp-orphan-monitor.git
cd cdp-orphan-monitor
```
2. **Make the Script Executable**:

```bash
Copy
Edit
chmod +x check-aws-orphan.sh
```
3. **Run the Script**:

```bash
Copy
Edit
./check-aws-orphan.sh
```
The script will output a list of snapshot IDs that are not associated with any AMIs.


## Notes
- Dry Run: This script only identifies orphaned snapshots. It does not delete them. Review the list before taking any action.

- Permissions: Ensure that the AWS CLI is configured with credentials that have permissions to describe snapshots and images.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## Disclaimer
Use this script at your own risk. Always ensure that you have backups and have reviewed the snapshots before deletion.
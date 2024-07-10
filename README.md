# Report Repository

This repository contains `standard reports` and `customizations` for clients. Each folder includes a standard report, with subfolders for client-specific customizations. The `parameters` table contains common queries for users to filter the reports.

## Folder Structure

```plaintext
report-repo/
│ 
├── standard-report-1/
│   ├── queries-standard/
│   └── customization-client-name/
│       └── queries
│ 
├── standard-report-2/
│   ├── queries-standard/
│   └── customization-client-name/
│       └── queries
│ 
└── parameters/
    └── user-common-filtering-queries
```

# Overview
## Standard Reports
The standard reports provide a base set of data and visualizations that are applicable to most users. These reports are located in the standard-report directories.

### Standard Report
Includes the following:

- Queries Standard: Common queries that can be used to filter and analyze the data.
- Customizations: Each client may have specific requirements that necessitate customizations to the standard reports. These customizations are located inside the report folder as a subdirectories with the client name.

### Customization
Includes the following:
- Client Queries: Custom queries tailored to the specific needs of the Client.

## Parameters Folder
The parameters folder includes common queries that can be used across different reports and customizations. These queries help users filter and manipulate the data according to their needs.
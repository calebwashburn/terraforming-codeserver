# terraforming-codeserver
Terraform to stand up [code server](https://github.com/cdr/code-server) instance focused on supporting go development.  Helpful for developing in go on an iPad Pro using web version of vscode 

## Deploy to Supported IaaS

- [AWS](/aws/README.md)

## Getting Started
- Open Browser to https address of the DNS name assigned in terraform output
- Login using password provided as terraform output
- Ensure Go Tools are installed via View -> Command Pallette
- Search for "Go: Install/Update Tools"
- Select all
- Once completed, Refresh browser
- Start coding as terminal launches into a shell with GOPATH (/home/codeserver/go) set and needed tools installed. 
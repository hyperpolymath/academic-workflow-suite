Name:           academic-workflow-suite
Version:        {{VERSION}}
Release:        1%{?dist}
Summary:        Comprehensive academic workflow automation suite

License:        MIT
URL:            https://github.com/academicworkflow/suite
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
Requires:       glibc >= 2.28

%description
The Academic Workflow Suite provides tools and utilities for researchers,
students, and academics to manage their work more efficiently.

Features include research paper organization, citation management,
collaboration utilities, and integration with academic databases.

%prep
%setup -q

%build
# Build is handled externally
true

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/%{name}
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/doc/%{name}

# Install binaries
install -m 755 target/release/aws $RPM_BUILD_ROOT/%{_bindir}/aws

# Install documentation
install -m 644 README.md $RPM_BUILD_ROOT/%{_datadir}/doc/%{name}/
install -m 644 LICENSE $RPM_BUILD_ROOT/%{_datadir}/doc/%{name}/

%files
%{_bindir}/aws
%dir %{_sysconfdir}/%{name}
%doc %{_datadir}/doc/%{name}/README.md
%license %{_datadir}/doc/%{name}/LICENSE

%post
echo "Academic Workflow Suite has been installed successfully!"
echo "Run 'aws --help' to get started."

%changelog
* %(date "+%a %b %d %Y") Academic Workflow Suite Team <maintainers@academicworkflow.org> - {{VERSION}}-1
- See CHANGELOG.md for detailed changes

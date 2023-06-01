Name:          b20-565-01
Version:       1.0
Release:       1%{?dist}
Summary:       10.03.01
Group:         Testing
License:       GPL
URL:           https://github.com/princessDimetra/OSS_LABS
Source0:       %{name}-%{version}.tar.gz
BuildRequires: /bin/rm, /bin/mkdir, /bin/cp
Requires:      /bin/bash, /usr/bin/date
BuildArch:     noarch

%description
A test package

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 b20-565-01 %{buildroot}%{_bindir}

%files
%{_bindir}/b20-565-01

%changelog
* Thu Oct 16 2012 Bondarenko
- Added %{_bindir}/b20-565-01

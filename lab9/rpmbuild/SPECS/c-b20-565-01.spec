Name:       c-b20-565-01
Version:    1.0
Release:    1%{?dist}
Summary:    10.03.01
Group:      Testing
License:    GPL
URL:        https://github.com/princessDimetra/OSS_LABS
Source:     %{name}-%{version}.tar.gz
BuildRequires: gcc

%description
A test package

%prep
%setup -q

%build
gcc -O2 -o c-b20-565-01 c-b20-565-01.c

%install
mkdir -p %{buildroot}%{_bindir}
cp c-b20-565-01 %{buildroot}%{_bindir}

%files
%{_bindir}/c-b20-565-01

%changelog
* Thu Jun 01 2023 Bondarenko
- Added %{_bindir}/c-b20-565-01

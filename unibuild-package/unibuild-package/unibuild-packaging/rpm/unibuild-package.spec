#
# RPM Spec for Unibuild Package Builder
#

Name:		unibuild-package
Version:	1.0
Release:	1%{?dist}

Summary:	Unibuild Package Builder
BuildArch:	noarch
License:	Apache 2.0
Group:		Unspecified

Source0:	%{name}-%{version}.tar.gz

Patch0:         %{name}-00-nothing.patch
Patch1:         %{name}-01-nothing2.patch
Patch2:         %{name}-99-rpm-only.patch

Provides:	%{name} = %{version}-%{release}


# These two sections should be identical since the package uses its
# own code to build itself.

%if 0%{?el8}
BuildRequires:	dnf
%endif
BuildRequires:	make
BuildRequires:	rpm
BuildRequires:	rpm-build
BuildRequires:	rpm-with-deps
BuildRequires:	rpmdevtools
BuildRequires:	sudo
%if 0%{?el7}
BuildRequires:	yum
%endif

%if 0%{?el8}
Requires:	dnf
%endif
Requires:	make
Requires:	rpm
Requires:	rpm-build
Requires:	rpm-with-deps
Requires:	rpmdevtools
Requires:	sudo
%if 0%{?el7}
Requires:	yum
%endif


%define directory %{_includedir}/unibuild
%define docdir %{_docdir}/%{name}-%{version}

%description
A system for building installable packages for various operating
systems.  See documentation in %{docdir}.


%prep
%setup -q
%patch0 -p0
%patch1 -p0
%patch2 -p0

%install
%{__mkdir_p} $RPM_BUILD_ROOT/%{directory}
%{__install} -m 444 *.make $RPM_BUILD_ROOT/%{directory}

%{__mkdir_p} $RPM_BUILD_ROOT/%{docdir}
%{__install} -m 444 *.md $RPM_BUILD_ROOT/%{docdir}


%files
%defattr(-,root,root,-)
%{directory}/*
%{docdir}/*

#
# RPM Spec for Unibuild
#

Name:		unibuild
Version:	1.0
Release:	1%{?dist}

Summary:	Unibuild repository builder
BuildArch:	noarch
License:	Apache 2.0
Group:		Unspecified

Source0:	%{name}-%{version}.tar.gz

Provides:	%{name} = %{version}-%{release}

# These two sections should be identical since the package uses its
# own code to build itself.

BuildRequires:	createrepo
BuildRequires:	unibuild-package
BuildRequires:	m4
BuildRequires:	make

Requires:       createrepo
Requires:	unibuild-package
Requires:	m4
Requires:	make



%define directory %{_libexecdir}/%{name}
%define include %{_includedir}/%{name}
%define docdir %{_docdir}/%{name}-%{version}

%description 
A system for building repositories of packages on various kinds of
systems.  systems.  See documentation in %{docdir}.


%prep
%setup -q


%install
make \
    BINDIR=$RPM_BUILD_ROOT/%{_bindir} \
    INCLUDEDIR=$RPM_BUILD_ROOT/%{include} \
    LIBEXECDIR=$RPM_BUILD_ROOT/%{_libexecdir}/%{name} \
    LIBEXECINSTALLEDDIR=%{_libexecdir}/%{name} \
    DOCDIR=$RPM_BUILD_ROOT/%{docdir} \
    VERSION=%{version} \
    install

%files
%defattr(-,root,root,-)
%{_bindir}/*
%{directory}
%{docdir}/*
%{include}/*

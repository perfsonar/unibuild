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

BuildRequires:	unibuild-package
BuildRequires:	make

# TODO: Re-enable this
Requires:       createrepo
Requires:	unibuild-package
Requires:	make



%define directory %{_libexecdir}/%{name}
%define docdir %{_docdir}/%{name}-%{version}

%description 
A system for building repositories of packages on various kinds of
systems.  systems.  See documentation in %{docdir}.


%prep
%setup -q


%install
make \
    BINDIR=$RPM_BUILD_ROOT/%{_bindir} \
    LIBEXECDIR=$RPM_BUILD_ROOT/%{_libexecdir}/%{name} \
    LIBEXECINSTALLEDDIR=%{_libexecdir}/%{name} \
    DOCDIR=$RPM_BUILD_ROOT/%{docdir} \
    install

%files
%defattr(-,root,root,-)
%{_bindir}/*
%{directory}
%{docdir}/*

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
Requires:	make

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
%{__mkdir_p} $RPM_BUILD_ROOT/%{directory}
%{__cp} -r commands lib %{name} $RPM_BUILD_ROOT/%{directory}

%{__mkdir_p} $RPM_BUILD_ROOT/%{_bindir}
%{__ln_s} %{directory}/%{name} $RPM_BUILD_ROOT/%{_bindir}

%{__mkdir_p} $RPM_BUILD_ROOT/%{docdir}
%{__install} -m 444 *.md $RPM_BUILD_ROOT/%{docdir}


%files
%defattr(-,root,root,-)
%{_bindir}/*
%{directory}/*
%{docdir}/*

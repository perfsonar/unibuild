#
# RPM Spec for Unibuild Hello RPM
#

Name:		hello-rpm
Version:	1.0
Release:	1%{?dist}

Summary:	Hello world from Unibuild for RPM-based systems

BuildArch:	noarch
License:	Apache 2.0
Group:		Utilities/Text
Vendor:		The perfSONAR Development Team <perfsonar-developer@internet2.edu>
URL:		https://github.com/perfsonar/unibuild

Source0:	%{name}-%{version}.tar.gz

Provides:	%{name} = %{version}-%{release}


%description
This is the hello world example from unibuild for RPM-based systems.


%prep
%setup -q


%install
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
make \
     BINDIR=$RPM_BUILD_ROOT/%{_bindir} \
     install


%clean
make clean


%files
%defattr(-,root,root)
%{_bindir}/*
